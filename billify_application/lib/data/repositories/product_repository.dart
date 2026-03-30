import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/models/product_model.dart';

class ProductRepository {
  final LocalStorageService _storage;
  final String _userId;
  final String _businessId;

  ProductRepository(this._storage, this._userId, this._businessId);

  String get _productDataKey => AppConstants.businessKey(_userId, _businessId, AppConstants.keyProductData);

  Future<void> saveProduct(ProductModel product) async {
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
  }

  Future<void> saveProducts(List<ProductModel> productsToUpdate) async {
    final products = getProducts();
    
    for (var updatedProduct in productsToUpdate) {
      final index = products.indexWhere((p) => p.id == updatedProduct.id);
      if (index >= 0) {
        products[index] = updatedProduct;
      } else {
        products.add(updatedProduct);
      }
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
    final products = getProducts();
    try {
      return products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteProduct(String id) async {
    final products = getProducts();
    products.removeWhere((p) => p.id == id);
    await _storage.setString(
      _productDataKey,
      jsonEncode(products.map((e) => e.toJson()).toList()),
    );
  }
}
