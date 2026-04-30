import 'dart:convert';
import 'package:billify/core/constants/app_constants.dart';
import 'package:billify/core/services/local_storage_service.dart';
import 'package:billify/data/models/user_model.dart';

abstract class AuthDatasource {
  Future<bool> register(UserModel user);
  Future<bool> login(String phoneNumber, String password);
  Future<void> logout();
  UserModel? getUser();
  bool isLoggedIn();
  Future<void> setAsLoggedInUser(UserModel user);
}

class LocalAuthDatasource implements AuthDatasource {
  final LocalStorageService _storage;

  LocalAuthDatasource(this._storage);

  @override
  Future<void> setAsLoggedInUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.setString(AppConstants.keyUserData, userJson);
    await _storage.setBool(AppConstants.keyIsLoggedIn, true);
  }

  @override
  Future<bool> register(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.setString(AppConstants.keyUserData, userJson);
    return true;
  }

  @override
  Future<bool> login(String phoneNumber, String password) async {
    final userJson = _storage.getString(AppConstants.keyUserData);
    if (userJson != null) {
      final user = UserModel.fromJson(jsonDecode(userJson));
      if (user.mobile == phoneNumber && user.password == password) {
        await _storage.setBool(AppConstants.keyIsLoggedIn, true);
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> logout() async {
    await _storage.setBool(AppConstants.keyIsLoggedIn, false);
  }

  @override
  UserModel? getUser() {
    final userJson = _storage.getString(AppConstants.keyUserData);
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  @override
  bool isLoggedIn() {
    return _storage.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }
}
