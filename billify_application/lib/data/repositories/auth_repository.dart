import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/datasources/auth_datasource.dart';
import 'package:billify_application/data/datasources/remote_auth_datasource.dart';
import 'package:billify_application/data/models/user_model.dart';

class AuthRepository {
  final LocalAuthDatasource _localDatasource;
  final RemoteAuthDatasource _remoteDatasource;
  final LocalStorageService _storage;

  AuthRepository(this._localDatasource, this._remoteDatasource, this._storage);

  Future<Map<String, dynamic>> registerWithDetails(
    Map<String, dynamic> data,
  ) async {
    final response = await _remoteDatasource.registerWithDetails(data);
    return response;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _remoteDatasource.loginWithResponse(email, password);

    if (response['token'] != null) {
      // 1. Save token
      await _storage.setString(AppConstants.keyToken, response['token']);

      // 2. Save user data
      final user = UserModel.fromJson(response['user']);
      await _localDatasource.setAsLoggedInUser(user);

      // 3. Save initial business data correctly scoped to user
      if (response['businesses'] != null &&
          (response['businesses'] as List).isNotEmpty) {
        final List<dynamic> businessesJson = response['businesses'];
        final userId = user.businessOwnerId ?? user.email;

        // Save full business list to user-scoped key
        await _storage.setString(
          AppConstants.userKey(userId, AppConstants.keyBusinessData),
          jsonEncode(businessesJson),
        );

        // Set first business as current in user-scoped key
        final firstBusinessId = businessesJson[0]['id'].toString();
        await _storage.setString(
          AppConstants.userKey(userId, AppConstants.keyCurrentBusinessId),
          firstBusinessId,
        );
      }
    }

    return response;
  }

  Future<void> setAsLoggedInUser(UserModel user) async {
    await _localDatasource.setAsLoggedInUser(user);
  }

  Future<void> logout() async {
    await _localDatasource.logout();
    await _storage.remove(AppConstants.keyToken);
    await _storage.remove(AppConstants.keyCurrentBusinessId);
  }

  UserModel? getUser() {
    return _localDatasource.getUser();
  }

  bool isLoggedIn() {
    return _localDatasource.isLoggedIn() &&
        _storage.getString(AppConstants.keyToken) != null;
  }
}
