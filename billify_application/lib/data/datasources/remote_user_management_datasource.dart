import 'package:billify/core/constants/api_endpoints.dart';
import 'package:billify/core/errors/app_exception.dart';
import 'package:billify/core/services/api_service.dart';
import 'package:billify/core/utils/app_logger.dart';
import 'package:billify/data/models/role_model.dart';
import 'package:billify/data/models/user_model.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteUserManagementDatasourceProvider =
    Provider<RemoteUserManagementDatasource>((ref) {
      return RemoteUserManagementDatasource(ref);
    });

class RemoteUserManagementDatasource {
  final Ref _ref;

  RemoteUserManagementDatasource(this._ref);

  ApiService get _apiService => _ref.read(apiServiceProvider);

  // ============ Staff / Users ============

  Future<List<UserModel>> getUsers(String businessId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.getUsersByBusiness(businessId),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['users'] ?? [];
        return data.map((e) => UserModel.fromJson(e)).toList();
      }
      return [];
    } on AppException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Error fetching users', tag: 'RemoteUserManagement', error: e, stackTrace: stack);
      throw AppException(message: 'Failed to retrieve staff users: $e');
    }
  }

  Future<UserModel?> createUser(UserModel user, String businessId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.createUser,
        data: {...user.toJson(), 'business_id': int.tryParse(businessId)},
      );
      if (response.statusCode == 201) {
        return UserModel.fromJson(response.data['user']);
      }
      return null;
    } on AppException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Error creating user', tag: 'RemoteUserManagement', error: e, stackTrace: stack);
      throw AppException(message: 'Failed to create user: $e');
    }
  }

  Future<bool> updateUser(UserModel user, String businessId) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.updateUser(user.id!),
        data: {...user.toJson(), 'business_id': int.tryParse(businessId)},
      );
      return response.statusCode == 200;
    } on AppException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Error updating user', tag: 'RemoteUserManagement', error: e, stackTrace: stack);
      throw AppException(message: 'Failed to update user: $e');
    }
  }

  Future<bool> deleteUser(String id, String businessId) async {
    try {
      final response = await _apiService.delete(
        ApiEndpoints.deleteUser(id),
        queryParameters: {'business_id': businessId},
      );
      return response.statusCode == 200;
    } on AppException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Error deleting user', tag: 'RemoteUserManagement', error: e, stackTrace: stack);
      throw AppException(message: 'Failed to delete user: $e');
    }
  }

  // ============ Roles & Permissions ============

  Future<List<RoleModel>> getRoles(String businessId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.getRolesByBusiness(businessId),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['roles'] ?? [];

        // Fetch permissions concurrently using Future.wait to eliminate N+1 latency waterfall
        final futures = data.map((roleJson) async {
          final role = RoleModel.fromJson(roleJson);
          try {
            final perms = await getPermissionsForRole(role.id);
            return role.copyWith(permissions: perms);
          } catch (_) {
            return role;
          }
        });

        return await Future.wait(futures);
      }
      return [];
    } on AppException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Error fetching roles', tag: 'RemoteUserManagement', error: e, stackTrace: stack);
      throw AppException(message: 'Failed to retrieve roles: $e');
    }
  }

  Future<Map<PermissionModule, List<PermissionAction>>> getPermissionsForRole(
    String roleId,
  ) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.getPermissionsByRole(roleId),
      );
      if (response.statusCode == 200) {
        return RoleModel.parsePermissions(response.data);
      }
      return {};
    } on AppException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Error fetching permissions for role $roleId', tag: 'RemoteUserManagement', error: e, stackTrace: stack);
      throw AppException(message: 'Failed to retrieve role permissions: $e');
    }
  }

  Future<RoleModel?> createRole(RoleModel role, String businessId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.createRole,
        data: {'name': role.name, 'business_id': int.tryParse(businessId)},
      );
      if (response.statusCode == 201) {
        final newRole = RoleModel.fromJson(response.data['role']);
        await saveRolePermissions(newRole.id, role);
        return newRole.copyWith(permissions: role.permissions);
      }
      return null;
    } on AppException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Error creating role', tag: 'RemoteUserManagement', error: e, stackTrace: stack);
      throw AppException(message: 'Failed to create role: $e');
    }
  }

  Future<bool> updateRole(RoleModel role) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.updateRole(role.id),
        data: {'name': role.name},
      );
      if (response.statusCode == 200) {
        return await saveRolePermissions(role.id, role);
      }
      return false;
    } on AppException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Error updating role', tag: 'RemoteUserManagement', error: e, stackTrace: stack);
      throw AppException(message: 'Failed to update role: $e');
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
    } on AppException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Error saving role permissions', tag: 'RemoteUserManagement', error: e, stackTrace: stack);
      throw AppException(message: 'Failed to save role permissions: $e');
    }
  }

  // ============ Profile ============

  Future<bool> updateProfile(UserModel user) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.updateProfile,
        data: {'name': user.name, 'mobile': user.mobile, 'photo': user.photo},
      );
      return response.statusCode == 200;
    } on AppException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Error updating profile', tag: 'RemoteUserManagement', error: e, stackTrace: stack);
      throw AppException(message: 'Failed to update profile: $e');
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.changePassword,
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
      return response.statusCode == 200;
    } on AppException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Error changing password', tag: 'RemoteUserManagement', error: e, stackTrace: stack);
      throw AppException(message: 'Failed to change password: $e');
    }
  }
}
