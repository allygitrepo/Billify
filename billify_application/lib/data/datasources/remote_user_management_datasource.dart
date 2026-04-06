import 'package:billify_application/core/constants/api_endpoints.dart';
import 'package:billify_application/core/services/api_service.dart';
import 'package:billify_application/data/models/role_model.dart';
import 'package:billify_application/data/models/user_model.dart';
import 'package:billify_application/data/models/user_permission.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteUserManagementDatasourceProvider = Provider<RemoteUserManagementDatasource>((ref) {
  return RemoteUserManagementDatasource(ref);
});

class RemoteUserManagementDatasource {
  final Ref _ref;

  RemoteUserManagementDatasource(this._ref);

  ApiService get _apiService => _ref.read(apiServiceProvider);

  // ============ Staff / Users ============

  Future<List<UserModel>> getUsers(String businessId) async {
    try {
      final response = await _apiService.get(ApiEndpoints.getUsersByBusiness(businessId));
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['users'];
        return data.map((e) => UserModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching users: $e");
      return [];
    }
  }

  Future<UserModel?> createUser(UserModel user, String businessId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.createUser,
        data: {
          ...user.toJson(),
          'business_id': int.tryParse(businessId),
        },
      );
      if (response.statusCode == 201) {
        return UserModel.fromJson(response.data['user']);
      }
      return null;
    } catch (e) {
      print("Error creating user: $e");
      return null;
    }
  }

  Future<bool> updateUser(UserModel user, String businessId) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.updateUser(user.id!),
        data: {
          ...user.toJson(),
          'business_id': int.tryParse(businessId),
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating user: $e");
      return false;
    }
  }

  Future<bool> deleteUser(String id, String businessId) async {
    try {
      final response = await _apiService.delete(
        ApiEndpoints.deleteUser(id),
        queryParameters: {'business_id': businessId},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }

  // ============ Roles & Permissions ============

  Future<List<RoleModel>> getRoles(String businessId) async {
    try {
      final response = await _apiService.get(ApiEndpoints.getRolesByBusiness(businessId));
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['roles'];
        
        final List<RoleModel> roles = [];
        for (var roleJson in data) {
          final role = RoleModel.fromJson(roleJson);
          // Fetch permissions separately for each role
          final perms = await getPermissionsForRole(role.id);
          roles.add(role.copyWith(permissions: perms));
        }
        return roles;
      }
      return [];
    } catch (e) {
      print("Error fetching roles: $e");
      return [];
    }
  }

  Future<Map<PermissionModule, List<PermissionAction>>> getPermissionsForRole(String roleId) async {
    try {
      final response = await _apiService.get(ApiEndpoints.getPermissionsByRole(roleId));
      if (response.statusCode == 200) {
        return RoleModel.parsePermissions(response.data);
      }
      return {};
    } catch (e) {
      print("Error fetching permissions for role $roleId: $e");
      return {};
    }
  }

  Future<RoleModel?> createRole(RoleModel role, String businessId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.createRole,
        data: {
          'name': role.name,
          'business_id': int.tryParse(businessId),
        },
      );
      if (response.statusCode == 201) {
        final newRole = RoleModel.fromJson(response.data['role']);
        // Save initial permissions
        await saveRolePermissions(newRole.id, role);
        return newRole.copyWith(permissions: role.permissions);
      }
      return null;
    } catch (e) {
      print("Error creating role: $e");
      return null;
    }
  }

  Future<bool> updateRole(RoleModel role) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.updateRole(role.id),
        data: {
          'name': role.name,
        },
      );
      if (response.statusCode == 200) {
        return await saveRolePermissions(role.id, role);
      }
      return false;
    } catch (e) {
      print("Error updating role: $e");
      return false;
    }
  }

  Future<bool> saveRolePermissions(String roleId, RoleModel role) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.savePermissions,
        data: {
          'role_id': int.tryParse(roleId),
          'permissions': role.toBackendPermissions(),
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error saving permissions: $e");
      return false;
    }
  }

  // ============ Profile ============

  Future<bool> updateProfile(UserModel user) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.updateProfile,
        data: {
          'name': user.name,
          'mobile': user.mobile,
          'photo': user.photo,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating profile: $e");
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.changePassword,
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error changing password: $e");
      return false;
    }
  }
}
