import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import 'package:billify/core/constants/app_constants.dart';
import 'package:billify/core/services/local_storage_service.dart';
import 'package:billify/data/datasources/auth_datasource.dart';
import 'package:billify/data/datasources/remote_auth_datasource.dart';
import 'package:billify/data/models/user_model.dart';

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

  Future<Map<String, dynamic>> requestOtp(String email) async {
    return await _remoteDatasource.requestOtp(email);
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    return await _remoteDatasource.verifyOtp(email, otp);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _remoteDatasource.loginWithResponse(email, password);
    return _handleAuthResponse(response);
  }

  // Step 1: Initialization using singleton pattern (required for v7.2.0)
  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn.instance;

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      debugPrint('DEBUG: Starting Google Sign-In process...');

      // Step 1 & 5: Ensure correct serverClientId is used for backend verification
      await _googleSignIn.initialize(
        serverClientId:
            '259733920973-v1mkjstvigkviviiucjb3313qvo0b4kb.apps.googleusercontent.com',
      );

      // Step 2: Implement login flow
      final gsi.GoogleSignInAccount? account = await _googleSignIn
          .authenticate();

      if (account == null) {
        debugPrint('DEBUG: Google Sign-In cancelled by user');
        return {'success': false, 'message': 'User cancelled'};
      }

      // Step 7: Debug logs
      print("Google account: ${account.email}");

      final gsi.GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      print("ID Token: $idToken");

      if (idToken == null) {
        debugPrint('DEBUG: Failed to obtain idToken');
        return {
          'success': false,
          'message': 'Failed to obtain Google ID Token',
        };
      }

      try {
        final response = await _remoteDatasource.googleLogin(idToken);
        debugPrint('DEBUG: Backend Google Login response: $response');

        // Finalize session management
        final authResult = await _handleAuthResponse(response);
        return {
          "success": true,
          "idToken": idToken,
          "email": account.email,
          "name": account.displayName,
          "photo": account.photoUrl,
          ...authResult, // Merge with backend response (token, user, etc)
        };
      } catch (e, stack) {
        debugPrint('DEBUG: Backend Google Login threw error: $e');
        debugPrint('DEBUG: Stack trace: $stack');
        return {"success": false, "message": e.toString()};
      }
    } catch (e, stack) {
      debugPrint('DEBUG: Google Sign-In Exception: $e');
      debugPrint('DEBUG: Stack trace: $stack');
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> _handleAuthResponse(
    Map<String, dynamic> response,
  ) async {
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
    // Completely clear all local storage to ensure the next login must fetch everything from the DB
    await _storage.clearAll();
  }

  UserModel? getUser() {
    return _localDatasource.getUser();
  }

  bool isLoggedIn() {
    return _localDatasource.isLoggedIn() &&
        _storage.getString(AppConstants.keyToken) != null;
  }
}
