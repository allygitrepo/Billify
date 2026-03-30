import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/models/business_model.dart';

abstract class BusinessDatasource {
  Future<bool> saveBusiness(BusinessModel business);
  List<BusinessModel> getBusinesses();
  String? getCurrentBusinessId();
  Future<bool> setCurrentBusinessId(String id);
  Future<void> clearAll();
}

class LocalBusinessDatasource implements BusinessDatasource {
  final LocalStorageService _storage;

  LocalBusinessDatasource(this._storage);

  @override
  Future<bool> saveBusiness(BusinessModel business) async {
    final businesses = getBusinesses();
    final index = businesses.indexWhere((b) => b.id == business.id);
    
    if (index >= 0) {
      businesses[index] = business;
    } else {
      businesses.add(business);
    }

    final businessesJson = jsonEncode(businesses.map((e) => e.toJson()).toList());
    final saved = await _storage.setString(AppConstants.keyBusinessData, businessesJson);
    
    // If it's the first business, set it as current
    if (saved && getCurrentBusinessId() == null) {
      await setCurrentBusinessId(business.id);
    }
    
    return saved;
  }

  @override
  List<BusinessModel> getBusinesses() {
    final businessesJson = _storage.getString(AppConstants.keyBusinessData);
    if (businessesJson != null) {
      try {
        final List<dynamic> list = jsonDecode(businessesJson);
        return list.map((e) => BusinessModel.fromJson(e)).toList();
      } catch (e) {
        // Migration: If it's a single object instead of a list
        try {
          final item = BusinessModel.fromJson(jsonDecode(businessesJson));
          return [item];
        } catch (_) {
          return [];
        }
      }
    }
    return [];
  }

  @override
  String? getCurrentBusinessId() {
    return _storage.getString(AppConstants.keyCurrentBusinessId);
  }

  @override
  Future<bool> setCurrentBusinessId(String id) async {
    return await _storage.setString(AppConstants.keyCurrentBusinessId, id);
  }

  @override
  Future<void> clearAll() async {
    await _storage.remove(AppConstants.keyBusinessData);
    await _storage.remove(AppConstants.keyCurrentBusinessId);
  }
}
