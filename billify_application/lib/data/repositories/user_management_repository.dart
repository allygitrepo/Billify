import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/datasources/remote_user_management_datasource.dart';
import 'package:billify_application/data/models/role_model.dart';
import 'package:billify_application/data/models/user_model.dart';

class UserManagementRepository {
  final LocalStorageService _storage;
  final RemoteUserManagementDatasource _remoteDatasource;

  UserManagementRepository(this._storage, this._remoteDatasource);

  String _getRoleKey(String businessId) => 'business_${businessId}_${AppConstants.keyRoleData}';
  String _getUsersListKey(String businessId) => 'business_${businessId}_${AppConstants.keyUsersList}';

  // ============ Syncing ============

  Future<void> syncAll(String businessId) async {
    try {
      final roles = await _remoteDatasource.getRoles(businessId);
      if (roles.isNotEmpty) {
        await saveRoles(businessId, roles);
      }

      final users = await _remoteDatasource.getUsers(businessId);
      if (users.isNotEmpty) {
        await saveUsers(businessId, users);
      }
    } catch (e) {
      print("Error syncing staff data: $e");
    }
  }

  // ============ Role Management ============

  Future<List<RoleModel>> getRoles(String businessId) async {
    final rolesJson = _storage.getString(_getRoleKey(businessId));
    if (rolesJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(rolesJson);
      return decoded.map((e) => RoleModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRoles(String businessId, List<RoleModel> roles) async {
    final rolesJson = jsonEncode(roles.map((e) => e.toJson()).toList());
    await _storage.setString(_getRoleKey(businessId), rolesJson);
  }

  Future<RoleModel?> addRole(String businessId, RoleModel role) async {
    final newRole = await _remoteDatasource.createRole(role, businessId);
    if (newRole != null) {
      final roles = await getRoles(businessId);
      roles.add(newRole);
      await saveRoles(businessId, roles);
      return newRole;
    }
    return null;
  }

  Future<bool> updateRole(String businessId, RoleModel role) async {
    final success = await _remoteDatasource.updateRole(role);
    if (success) {
      final roles = await getRoles(businessId);
      final index = roles.indexWhere((r) => r.id == role.id);
      if (index >= 0) {
        roles[index] = role;
        await saveRoles(businessId, roles);
      }
      return true;
    }
    return false;
  }

  // ============ User Management ============

  Future<List<UserModel>> getUsers(String businessId) async {
    final usersJson = _storage.getString(_getUsersListKey(businessId));
    if (usersJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(usersJson);
      return decoded.map((e) => UserModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveUsers(String businessId, List<UserModel> users) async {
    final usersJson = jsonEncode(users.map((e) => e.toJson()).toList());
    await _storage.setString(_getUsersListKey(businessId), usersJson);
  }

  Future<UserModel?> addUser(String businessId, UserModel user) async {
    final newUser = await _remoteDatasource.createUser(user, businessId);
    if (newUser != null) {
      final users = await getUsers(businessId);
      users.add(newUser);
      await saveUsers(businessId, users);
      return newUser;
    }
    return null;
  }

  Future<bool> updateUser(String businessId, UserModel user) async {
    final success = await _remoteDatasource.updateUser(user, businessId);
    if (success) {
      final users = await getUsers(businessId);
      final index = users.indexWhere((u) => u.id == user.id);
      if (index >= 0) {
        users[index] = user;
        await saveUsers(businessId, users);
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteUser(String businessId, String userId) async {
    final success = await _remoteDatasource.deleteUser(userId, businessId);
    if (success) {
      final users = await getUsers(businessId);
      users.removeWhere((u) => u.id == userId);
      await saveUsers(businessId, users);
      return true;
    }
    return false;
  }

  // ============ Profile ============

  Future<bool> updateProfile(UserModel user) async {
    return await _remoteDatasource.updateProfile(user);
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    return await _remoteDatasource.changePassword(oldPassword, newPassword);
  }
}
