import 'dart:convert';
import 'package:billify/core/constants/app_constants.dart';
import 'package:billify/core/services/local_storage_service.dart';
import 'package:billify/data/datasources/remote_category_datasource.dart';
import 'package:billify/data/models/category_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CategoryRepository {
  final LocalStorageService _storage;
  final RemoteCategoryDatasource _remoteDatasource;
  final String _userId;
  final String _businessId;

  CategoryRepository(
    this._storage,
    this._remoteDatasource,
    this._userId,
    this._businessId,
  );

  String get _categoryDataKey => AppConstants.businessKey(
    _userId,
    _businessId,
    AppConstants.keyCategoryData,
  );

  Future<void> fetchAndSyncCategories() async {
    if (int.tryParse(_businessId) == null) {
      return;
    }
    try {
      final remoteCategories = await _remoteDatasource.getCategories(
        _businessId,
      );
      await _storage.setString(
        _categoryDataKey,
        jsonEncode(remoteCategories.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      // Failed to sync, fallback to local storage
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> saveCategory(CategoryModel category) async {
    if (int.tryParse(_businessId) == null) {
      debugPrint("Skipping remote category save: Business ID is temporary.");
      return;
    }
    try {
      CategoryModel? savedCategory;
      if (category.id.isEmpty || category.id.contains('-')) {
        // Assume creating new if ID is UUID or empty
        savedCategory = await _remoteDatasource.createCategory(
          category,
          _businessId,
        );
      } else {
        // Update existing
        savedCategory = await _remoteDatasource.updateCategory(category);
      }

      if (savedCategory != null) {
        final categories = getCategories();
        final index = categories.indexWhere(
          (c) => c.id == category.id || c.id == savedCategory!.id,
        );

        if (index >= 0) {
          categories[index] = savedCategory;
        } else {
          categories.add(savedCategory);
        }

        await _storage.setString(
          _categoryDataKey,
          jsonEncode(categories.map((e) => e.toJson()).toList()),
        );
      } else {
        throw Exception("Failed to save category on server");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception(
          e.response?.data['message'] ?? 'Category already exists',
        );
      }
      throw Exception('Network error while saving category');
    } catch (e) {
      throw e;
    }
  }

  List<CategoryModel> getCategories() {
    final data = _storage.getString(_categoryDataKey);
    if (data == null) return [];

    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<void> deleteCategory(String id) async {
    try {
      final success = await _remoteDatasource.deleteCategory(id);
      if (success) {
        final categories = getCategories();
        categories.removeWhere((c) => c.id == id);
        await _storage.setString(
          _categoryDataKey,
          jsonEncode(categories.map((e) => e.toJson()).toList()),
        );
      } else {
        throw Exception("Failed to delete category on server");
      }
    } catch (e) {
      throw Exception('Network error while deleting category');
    }
  }
}
