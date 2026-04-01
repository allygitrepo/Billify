import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/models/role_model.dart';
import 'package:billify_application/data/models/user_model.dart';

class UserManagementRepository {
  final LocalStorageService _storage;

  UserManagementRepository(this._storage);

  String _getRoleKey(String businessId) => 'business_${businessId}_${AppConstants.keyRoleData}';
  String _getUsersListKey(String businessId) => 'business_${businessId}_${AppConstants.keyUsersList}';

  // Role Management
  Future<List<RoleModel>> getRoles(String businessId) async {
    final rolesJson = _storage.getString(_getRoleKey(businessId));
    if (rolesJson == null) return [];
    final List<dynamic> decoded = jsonDecode(rolesJson);
    return decoded.map((e) => RoleModel.fromJson(e)).toList();
  }

  Future<void> saveRoles(String businessId, List<RoleModel> roles) async {
    final rolesJson = jsonEncode(roles.map((e) => e.toJson()).toList());
    await _storage.setString(_getRoleKey(businessId), rolesJson);
  }

  // User Management within Business
  Future<List<UserModel>> getUsers(String businessId) async {
    final usersJson = _storage.getString(_getUsersListKey(businessId));
    if (usersJson == null) return [];
    final List<dynamic> decoded = jsonDecode(usersJson);
    return decoded.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> saveUsers(String businessId, List<UserModel> users) async {
    final usersJson = jsonEncode(users.map((e) => e.toJson()).toList());
    await _storage.setString(_getUsersListKey(businessId), usersJson);
  }
}
