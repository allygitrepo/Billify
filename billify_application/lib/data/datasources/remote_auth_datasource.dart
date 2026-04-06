import 'package:billify_application/core/constants/api_endpoints.dart';
import 'package:billify_application/core/services/api_service.dart';
import 'package:billify_application/data/datasources/auth_datasource.dart';
import 'package:billify_application/data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteAuthDatasourceProvider = Provider<RemoteAuthDatasource>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return RemoteAuthDatasource(apiService);
});

class RemoteAuthDatasource implements AuthDatasource {
  final ApiService _apiService;

  RemoteAuthDatasource(this._apiService);

  @override
  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      
      if (response.statusCode == 200) {
        // Note: The response contains { token, user, businesses }. 
        // We'll return true here and handle the data in the repository/provider.
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> register(UserModel user) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.register,
        data: user.toJson(), // User registration might need business_name etc.
      );
      
      if (response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Helper method for the Repository to get the full login response
  Future<Map<String, dynamic>> loginWithResponse(String email, String password) async {
    final response = await _apiService.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return response.data;
  }

  // Helper method for Registration with more fields
  Future<Map<String, dynamic>> registerWithDetails(Map<String, dynamic> registrationData) async {
    final response = await _apiService.post(
      ApiEndpoints.register,
      data: registrationData,
    );
    return response.data;
  }

  @override
  Future<void> logout() async {
    // Typically involves clearing token on server if using refresh tokens
    // For simple JWT, we just clear it locally.
  }

  @override
  UserModel? getUser() => null; // Use local storage for this

  @override
  bool isLoggedIn() => false; // Use local storage for this

  @override
  Future<void> setAsLoggedInUser(UserModel user) async {} // Handled via repository+local storage
}
