import 'package:billify_application/core/constants/api_endpoints.dart';
import 'package:billify_application/core/services/api_service.dart';
import 'package:billify_application/data/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteProductDatasourceProvider = Provider<RemoteProductDatasource>((
  ref,
) {
  final apiService = ref.read(apiServiceProvider);
  return RemoteProductDatasource(apiService);
});

class RemoteProductDatasource {
  final ApiService _apiService;

  RemoteProductDatasource(this._apiService);

  Future<List<ProductModel>> getProducts(String businessId) async {
    final response = await _apiService.get(
      ApiEndpoints.getProducts(businessId),
    );
    if (response.statusCode == 200) {
      final data = response.data['products'] as List;
      return data.map((json) => ProductModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<ProductModel?> createProduct(
    ProductModel product,
    String businessId,
  ) async {
    final Map<String, dynamic> payload = product.toJson();
    payload['business_id'] = businessId; // Explicitly ensure business_id is sent

    final response = await _apiService.post(
      ApiEndpoints.createProduct,
      data: payload,
    );
    if (response.statusCode == 201) {
      return ProductModel.fromJson(response.data['product']);
    }
    return null;
  }

  Future<ProductModel?> updateProduct(ProductModel product) async {
    final response = await _apiService.put(
      ApiEndpoints.updateProduct(product.id),
      data: product.toJson(),
    );
    if (response.statusCode == 200) {
      return ProductModel.fromJson(response.data['product']);
    }
    return null;
  }

  Future<bool> deleteProduct(String id) async {
    final response = await _apiService.delete(ApiEndpoints.deleteProduct(id));
    return response.statusCode == 200;
  }
}
