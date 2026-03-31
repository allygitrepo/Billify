import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/models/category_model.dart';

class CategoryRepository {
  final LocalStorageService _storage;
  final String _userId;
  final String _businessId;

  CategoryRepository(this._storage, this._userId, this._businessId);

  String get _categoryDataKey => AppConstants.businessKey(_userId, _businessId, AppConstants.keyCategoryData);

  Future<void> saveCategory(CategoryModel category) async {
    final categories = getCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    
    if (index >= 0) {
      categories[index] = category;
    } else {
      categories.add(category);
    }
    
    await _storage.setString(
      _categoryDataKey,
      jsonEncode(categories.map((e) => e.toJson()).toList()),
    );
  }

  List<CategoryModel> getCategories() {
    final data = _storage.getString(_categoryDataKey);
    if (data == null) return [];
    
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<void> deleteCategory(String id) async {
    final categories = getCategories();
    categories.removeWhere((c) => c.id == id);
    await _storage.setString(
      _categoryDataKey,
      jsonEncode(categories.map((e) => e.toJson()).toList()),
    );
  }
}
