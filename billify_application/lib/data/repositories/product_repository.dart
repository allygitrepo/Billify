import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/datasources/remote_product_datasource.dart';
import 'package:billify_application/data/models/product_model.dart';
import 'package:dio/dio.dart';

class ProductRepository {
  final LocalStorageService _storage;
  final RemoteProductDatasource _remoteDatasource;
  final String _userId;
  final String _businessId;

  ProductRepository(this._storage, this._remoteDatasource, this._userId, this._businessId);

  String get _productDataKey => AppConstants.businessKey(_userId, _businessId, AppConstants.keyProductData);

  Future<void> fetchAndSyncProducts() async {
    try {
      final remoteProducts = await _remoteDatasource.getProducts(_businessId);
      await _storage.setString(
        _productDataKey,
        jsonEncode(remoteProducts.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      // Failed to sync, fallback to local storage
      print("Error fetching products: $e");
    }
  }

  Future<void> saveProduct(ProductModel product) async {
    try {
      ProductModel? savedProduct;
      if (product.id.isEmpty || product.id.contains('-')) {
        savedProduct = await _remoteDatasource.createProduct(product, _businessId);
      } else {
        savedProduct = await _remoteDatasource.updateProduct(product);
      }

      if (savedProduct != null) {
        final products = getProducts();
        final index = products.indexWhere((p) => p.id == product.id || p.id == savedProduct!.id);
        
        if (index >= 0) {
           products[index] = savedProduct;
        } else {
           products.add(savedProduct);
        }
        
        await _storage.setString(
          _productDataKey,
          jsonEncode(products.map((e) => e.toJson()).toList()),
        );
      } else {
        throw Exception("Failed to save product on server");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception(e.response?.data['message'] ?? 'Product already exists');
      }
      throw Exception('Network error while saving product');
    } catch (e) {
      throw e;
    }
  }

  Future<void> saveProducts(List<ProductModel> productsToUpdate) async {
    // Note: If bulk updates are needed to server, they'd go here. 
    // Currently this is mostly used for bulk stock sync from Invoice Provider logic.
    final products = getProducts();
    for (var updatedProduct in productsToUpdate) {
      final index = products.indexWhere((p) => p.id == updatedProduct.id);
      if (index >= 0) {
        products[index] = updatedProduct;
      } else {
        products.add(updatedProduct);
      }
      // Async loop update to server ideally
      try {
        await _remoteDatasource.updateProduct(updatedProduct);
      } catch (_) {}
    }
    
    await _storage.setString(
      _productDataKey,
      jsonEncode(products.map((e) => e.toJson()).toList()),
    );
  }

  List<ProductModel> getProducts() {
    final data = _storage.getString(_productDataKey);
    if (data == null) return [];
    
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => ProductModel.fromJson(e)).toList();
  }

  ProductModel? getProductByBarcode(String barcode) {
    if (barcode.isEmpty) return null;
    final products = getProducts();
    for (var product in products) {
      if (product.hasVariants) {
        for (var variant in product.variants) {
          if (variant.sku == barcode) return product; // The UI matches it similarly
        }
      }
      if (product.barcode == barcode) return product;
    }
    return null;
  }

  Future<void> deleteProduct(String id) async {
    try {
      final success = await _remoteDatasource.deleteProduct(id);
      if (success) {
        final products = getProducts();
        products.removeWhere((p) => p.id == id);
        await _storage.setString(
          _productDataKey,
          jsonEncode(products.map((e) => e.toJson()).toList()),
        );
      } else {
         throw Exception("Failed to delete product on server");
      }
    } catch (e) {
      throw Exception('Network error while deleting product');
    }
  }
}
