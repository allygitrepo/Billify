import 'package:flutter/foundation.dart';
import 'package:billify/data/datasources/auth_datasource.dart';
import 'package:billify/data/models/user_model.dart';
import 'package:billify/data/repositories/auth_repository.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billify/providers/user_management_provider.dart';
import 'package:billify/data/models/role_model.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:billify/core/constants/app_constants.dart';
import 'package:billify/data/datasources/business_datasource.dart';
import 'package:billify/data/repositories/business_repository.dart';
import 'package:billify/providers/business_provider.dart';

import 'package:billify/data/datasources/remote_auth_datasource.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final localDatasource = LocalAuthDatasource(storage);
  final remoteDatasource = ref.watch(remoteAuthDatasourceProvider);
  return AuthRepository(localDatasource, remoteDatasource, storage);
});

class AuthState {
  final UserModel? user;
  final RoleModel? currentRole;
  final bool isLoggedIn;
  final bool isLoading;
  final String? loadingMessage;
  final String? error;
  final dynamic errorObject;

  AuthState({
    this.user,
    this.currentRole,
    this.isLoggedIn = false,
    this.isLoading = false,
    this.loadingMessage,
    this.error,
    this.errorObject,
  });

  bool hasPermission(PermissionModule module, PermissionAction action) {
    if (!isLoggedIn) return false;

    // 1. Global Admin Check (Role ID '1')
    // 2. Owner/Initial Setup Check (Role ID null)
    // 3. Fallback Admin Check (Internal IDs)
    if (user?.roleId == '1' ||
        user?.roleId == null ||
        currentRole?.id == 'owner_admin' ||
        currentRole?.id == 'fallback_admin') {
      return true;
    }

    // 4. Specific Role Check
    return currentRole?.hasPermission(module, action) ?? false;
  }

  AuthState copyWith({
    UserModel? user,
    RoleModel? currentRole,
    bool? isLoggedIn,
    bool? isLoading,
    String? loadingMessage,
    String? error,
    dynamic errorObject,
  }) {
    return AuthState(
      user: user ?? this.user,
      currentRole: currentRole ?? this.currentRole,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      error: error,
      errorObject: errorObject ?? this.errorObject,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final repo = ref.read(authRepositoryProvider);
    final user = repo.getUser();
    final isLoggedIn = repo.isLoggedIn();

    if (isLoggedIn && user != null) {
      // Load role async (initial load)
      _loadRoleForUser(user);
    }

    return AuthState(user: user, isLoggedIn: isLoggedIn);
  }

  Future<void> _loadRoleForUser(UserModel user) async {
    if (user.roleId == null) {
      print(
        "INFO: User has no roleId (Owner account). Granting full administrative permissions.",
      );
      final ownerRole = RoleModel(
        id: 'owner_admin',
        name: 'Owner',
        permissions: {
          for (var module in PermissionModule.values)
            module: [PermissionAction.all],
        },
      );
      state = state.copyWith(currentRole: ownerRole);
      return;
    }

    final repo = ref.read(userManagementRepositoryProvider);
    final storage = ref.read(localStorageServiceProvider);

    // 1. Determine scoped User ID for key lookups
    final userId = user.businessOwnerId ?? user.email;

    // 2. Resolve Business ID from Storage only to avoid Circular Dependency
    String? businessId = storage.getString(
      AppConstants.userKey(userId, AppConstants.keyCurrentBusinessId),
    );

    if (businessId == null || int.tryParse(businessId) == null) {
      debugPrint(
        "INFO: Business ID is null or non-numeric. Checking for Global Admin role...",
      );

      // Check if it's a known Global Admin role (ID 1)
      if (user.roleId == 1) {
        debugPrint(
          "SUCCESS: Global Admin detected (Role ID: 1). Granting full administrative access.",
        );
        final fullAccessRole = RoleModel(
          id: 'global_admin',
          name: 'Global Admin',
          permissions: {
            for (var module in PermissionModule.values)
              module: [PermissionAction.all],
          },
        );
        state = state.copyWith(
          currentRole: fullAccessRole,
          loadingMessage: "Global access granted",
        );
        return;
      }

      debugPrint(
        "WARNING: No business context found for non-global user ${user.name}. Fallback to setup required.",
      );
      return;
    }

    debugPrint(
      "DEBUG: Retrieving permissions for Role ${user.roleId} in Business $businessId",
    );
    state = state.copyWith(loadingMessage: "Retrieving role permissions...");

    try {
      final roles = await repo.getRoles(businessId);
      // Comparison using toString() to handle potential int vs String mismatches
      final role = roles.firstWhere(
        (r) => r.id.toString() == user.roleId.toString(),
      );
      state = state.copyWith(
        currentRole: role,
        loadingMessage: "Role loaded: ${role.name}",
      );
      debugPrint("SUCCESS: Permissions loaded for role: ${role.name}");
    } catch (e) {
      debugPrint(
        "WARNING: Role ${user.roleId} not found in business roles. Granting emergency fallback Admin access.",
      );
      print(
        "WARNING: Specific Role ${user.roleId} not found in business roles table.",
      );
      print(
        "INFO: Granting full administrative access as fallback for user ${user.name} (Role ID: ${user.roleId})",
      );

      final fullAccessRole = RoleModel(
        id: 'fallback_admin', // Standardized fallback ID
        name: 'Admin',
        permissions: {
          for (var module in PermissionModule.values)
            module: [PermissionAction.all],
        },
      );
      state = state.copyWith(
        currentRole: fullAccessRole,
        loadingMessage: "Ready as Administrator",
      );
    }

    // Ensure business details are synced (important for branding etc)
    await ref.read(businessProvider.notifier).sync();
  }

  Future<void> login(String email, String password) async {
    // Reset state to clean slate while loading to ensure no stale data is visible
    state = AuthState(
      isLoading: true,
      loadingMessage: "Verifying credentials with server...",
    );
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.login(email, password);
      await _handleLoginResponse(response);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorObject: e,
        error: e.toString(),
      );
    }
  }

  Future<void> loginWithGoogle() async {
    debugPrint('DEBUG: Starting Google Sign-In process...');
    // Reset state to clean slate while loading to ensure no stale data is visible
    state = AuthState(
      isLoading: true,
      loadingMessage: "Connecting to Google...",
    );
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.loginWithGoogle();
      debugPrint(
        'DEBUG: Google Sign-In response received in provider: $response',
      );
      await _handleLoginResponse(response);
    } catch (e, stack) {
      debugPrint('DEBUG: Google Sign-In provider caught error: $e');
      debugPrint('DEBUG: Provider stack trace: $stack');
      state = state.copyWith(
        isLoading: false,
        errorObject: e,
        error: e.toString(),
      );
    }
  }

  Future<void> _handleLoginResponse(Map<String, dynamic> response) async {
    final repo = ref.read(authRepositoryProvider);
    if (response['token'] != null) {
      debugPrint('DEBUG: Auth token found in response. Finalizing login...');
      final user = repo.getUser();
      state = state.copyWith(user: user, isLoggedIn: true);

      if (user != null) {
        state = state.copyWith(loadingMessage: "Detecting user role...");
        await _loadRoleForUser(user);

        state = state.copyWith(
          loadingMessage: "Synchronizing business data...",
        );
        await ref.read(businessProvider.notifier).sync();
      }
      state = state.copyWith(isLoading: false, loadingMessage: null);
      debugPrint('DEBUG: Login process completed successfully');
    } else {
      debugPrint('DEBUG: Login failed. Error message: ${response['message']}');
      state = state.copyWith(
        isLoading: false,
        error: response['message'] ?? 'Authentication failed',
      );
    }
  }

  Future<void> register(Map<String, dynamic> registrationData) async {
    state = state.copyWith(isLoading: true, error: null, errorObject: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.registerWithDetails(registrationData);

      if (response['user'] != null) {
        final user = UserModel.fromJson(response['user']);
        state = state.copyWith(user: user, isLoggedIn: false, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorObject: e,
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> requestOtp(String email) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      return await repo.requestOtp(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      return await repo.verifyOtp(email, otp);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile(
    UserModel updatedUser, {
    String? oldPassword,
    String? newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null, errorObject: null);
    try {
      final userMgmtRepo = ref.read(userManagementRepositoryProvider);

      // 1. Update Profile (Name, Mobile, Photo) on server
      final success = await userMgmtRepo.updateProfile(updatedUser);
      if (!success) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update profile on server',
        );
        return;
      }

      // 2. Handle Password Change if requested
      if (oldPassword != null && newPassword != null) {
        final passSuccess = await userMgmtRepo.changePassword(
          oldPassword,
          newPassword,
        );
        if (!passSuccess) {
          state = state.copyWith(
            isLoading: false,
            error:
                'Profile updated, but password change failed. Check your old password.',
          );
          return;
        }
      }

      // 3. Update the currently logged in user info in local storage
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.setAsLoggedInUser(updatedUser);

      // 4. Update state
      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorObject: e,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
