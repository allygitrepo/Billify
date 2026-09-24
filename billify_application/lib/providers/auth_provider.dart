import 'package:billify/core/constants/app_constants.dart';
import 'package:billify/core/utils/app_logger.dart';
import 'package:billify/data/datasources/auth_datasource.dart';
import 'package:billify/data/datasources/remote_auth_datasource.dart';
import 'package:billify/data/models/role_model.dart';
import 'package:billify/data/models/user_model.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:billify/data/repositories/auth_repository.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:billify/providers/user_management_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      AppLogger.info(
        "User has no roleId (Owner account). Granting owner permissions.",
        tag: 'AuthNotifier',
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
    final userId = (user.businessOwnerId?.isNotEmpty == true)
        ? user.businessOwnerId!
        : (user.email?.isNotEmpty == true)
            ? user.email!
            : user.mobile;

    // 2. Resolve Business ID from Storage only to avoid Circular Dependency
    String? businessId = storage.getString(
      AppConstants.userKey(userId, AppConstants.keyCurrentBusinessId),
    );

    if (businessId == null || int.tryParse(businessId) == null) {
      // Check if it's a known Global Admin role (ID 1)
      if (user.roleId == '1' || user.roleId?.toLowerCase() == 'admin') {
        AppLogger.info(
          "Global Admin detected. Granting full administrative access.",
          tag: 'AuthNotifier',
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

      AppLogger.warning(
        "No business context found for user ${user.name}.",
        tag: 'AuthNotifier',
      );
      return;
    }

    AppLogger.debug(
      "Retrieving permissions for Role ${user.roleId} in Business $businessId",
      tag: 'AuthNotifier',
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
      AppLogger.info("Permissions loaded for role: ${role.name}", tag: 'AuthNotifier');
    } catch (e) {
      AppLogger.warning(
        "Specific Role ${user.roleId} could not be loaded for user ${user.name}: $e",
        tag: 'AuthNotifier',
      );
      // Fail-closed security: Assign restricted permissions on failure rather than elevating to full Admin
      final restrictedRole = RoleModel(
        id: 'restricted_user',
        name: 'Restricted User',
        permissions: {},
      );
      state = state.copyWith(
        currentRole: restrictedRole,
        loadingMessage: "Ready (Restricted permissions)",
        error: "Unable to verify role permissions with server. Some features may be restricted.",
      );
    }

    // Ensure business details are synced (important for branding etc)
    await ref.read(businessProvider.notifier).sync();
  }

  Future<void> login(String phoneNumber, String password) async {
    // Reset state to clean slate while loading to ensure no stale data is visible
    state = AuthState(
      isLoading: true,
      loadingMessage: "Verifying credentials with server...",
    );
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.login(phoneNumber, password);
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
    AppLogger.debug('Starting Google Sign-In process...', tag: 'AuthNotifier');
    // Reset state to clean slate while loading to ensure no stale data is visible
    state = AuthState(
      isLoading: true,
      loadingMessage: "Connecting to Google...",
    );
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.loginWithGoogle();
      await _handleLoginResponse(response);
    } catch (e, stack) {
      AppLogger.error('Google Sign-In failed', tag: 'AuthNotifier', error: e, stackTrace: stack);
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
      AppLogger.info('Auth token verified. Finalizing login...', tag: 'AuthNotifier');
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
      AppLogger.info('Login process completed successfully', tag: 'AuthNotifier');
    } else {
      AppLogger.warning('Login failed: ${response['message']}', tag: 'AuthNotifier');
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

  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      return await repo.requestOtp(phoneNumber);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      return await repo.verifyOtp(phoneNumber, otp);
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
