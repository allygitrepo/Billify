import 'package:billify/core/constants/api_endpoints.dart';
import 'package:billify/core/services/api_service.dart';
import 'package:billify/data/models/category_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteCategoryDatasourceProvider = Provider<RemoteCategoryDatasource>((
  ref,
) {
  final apiService = ref.read(apiServiceProvider);
  return RemoteCategoryDatasource(apiService);
});

class RemoteCategoryDatasource {
  final ApiService _apiService;

  RemoteCategoryDatasource(this._apiService);

  Future<List<CategoryModel>> getCategories(String businessId) async {
    final response = await _apiService.get(
      ApiEndpoints.getCategories(businessId),
    );
    if (response.statusCode == 200) {
      final data = response.data['categories'] as List;
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<CategoryModel?> createCategory(
    CategoryModel category,
    String businessId,
  ) async {
    final response = await _apiService.post(
      ApiEndpoints.createCategory,
      data: {
        'business_id': businessId,
        'name': category.name,
        'description': category.description,
        'status': category.status,
      },
    );
    if (response.statusCode == 201) {
      return CategoryModel.fromJson(response.data['category']);
    }
    return null;
  }

  Future<CategoryModel?> updateCategory(CategoryModel category) async {
    final response = await _apiService.put(
      ApiEndpoints.updateCategory(category.id),
      data: {
        'name': category.name,
        'description': category.description,
        'status': category.status,
      },
    );
    if (response.statusCode == 200) {
      return CategoryModel.fromJson(response.data['category']);
    }
    return null;
  }

  Future<bool> deleteCategory(String id) async {
    final response = await _apiService.delete(ApiEndpoints.deleteCategory(id));
    return response.statusCode == 200;
  }
}
