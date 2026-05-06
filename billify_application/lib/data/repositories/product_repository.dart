import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:billify/core/constants/app_constants.dart';
import 'package:billify/core/services/local_storage_service.dart';
import 'package:billify/data/datasources/remote_product_datasource.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:dio/dio.dart';

class ProductRepository {
  final LocalStorageService _storage;
  final RemoteProductDatasource _remoteDatasource;
  final String _userId;
  final String _businessId;

  ProductRepository(
    this._storage,
    this._remoteDatasource,
    this._userId,
    this._businessId,
  );

  String get _productDataKey => AppConstants.businessKey(
    _userId,
    _businessId,
    AppConstants.keyProductData,
  );

  Future<void> fetchAndSyncProducts() async {
    if (int.tryParse(_businessId) == null) {
      return; // Skip sync for temporary or invalid business IDs
    }
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
    // 1. Always save locally first for immediate UI update
    final products = getProducts();
    final index = products.indexWhere((p) => p.id == product.id);

    if (index >= 0) {
      products[index] = product;
    } else {
      products.add(product);
    }

    await _storage.setString(
      _productDataKey,
      jsonEncode(products.map((e) => e.toJson()).toList()),
    );

    // 2. Try remote save if business ID is valid
    if (int.tryParse(_businessId) == null) {
      print("Skipping remote product save: Business ID $_businessId is temporary.");
      return;
    }

    try {
      ProductModel? savedProduct;
      if (product.id.isEmpty || product.id.contains('-')) {
        savedProduct = await _remoteDatasource.createProduct(
          product,
          _businessId,
        );
      } else {
        savedProduct = await _remoteDatasource.updateProduct(product);
      }

      if (savedProduct != null) {
        // Update local storage with server-assigned data (like real ID)
        final currentProducts = getProducts();
        final idx = currentProducts.indexWhere(
          (p) => p.id == product.id || p.id == savedProduct!.id,
        );

        if (idx >= 0) {
          currentProducts[idx] = savedProduct;
        } else {
          currentProducts.add(savedProduct);
        }

        await _storage.setString(
          _productDataKey,
          jsonEncode(currentProducts.map((e) => e.toJson()).toList()),
        );
      }
    } on DioException catch (e) {
      print("SAVE ERROR: ${e.response?.data ?? e.message}");
      // We don't rethrow here if it was already saved locally, 
      // but maybe we should if we want the user to know it's not on server.
      // For now, let's rethrow to maintain original behavior but keep local save.
      rethrow;
    } catch (e) {
      rethrow;
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
          if (variant.sku == barcode)
            return product; // The UI matches it similarly
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
