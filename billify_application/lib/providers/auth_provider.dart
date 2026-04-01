import 'package:billify_application/data/datasources/auth_datasource.dart';
import 'package:billify_application/data/models/user_model.dart';
import 'package:billify_application/data/repositories/auth_repository.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billify_application/providers/user_management_provider.dart';
import 'package:billify_application/data/models/role_model.dart';
import 'package:billify_application/data/models/user_permission.dart';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/data/datasources/business_datasource.dart';
import 'package:billify_application/data/repositories/business_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final datasource = LocalAuthDatasource(storage);
  return AuthRepository(datasource);
});

class AuthState {
  final UserModel? user;
  final RoleModel? currentRole;
  final bool isLoggedIn;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.currentRole,
    this.isLoggedIn = false,
    this.isLoading = false,
    this.error,
  });

  bool hasPermission(PermissionModule module, PermissionAction action) {
    if (isLoggedIn && user?.roleId == null) return true; // Owner has all permissions
    return currentRole?.hasPermission(module, action) ?? false;
  }

  AuthState copyWith({
    UserModel? user,
    RoleModel? currentRole,
    bool? isLoggedIn,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      currentRole: currentRole ?? this.currentRole,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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
    if (user.roleId == null) return;
    
    // We use storage directly to avoid a circular dependency with businessProvider during initialization
    final storage = ref.read(localStorageServiceProvider);
    
    // Scoping currentBusinessId lookup to the correct user (owner if staff, else self)
    final userId = user.businessOwnerId ?? user.email;
    final businessId = storage.getString(AppConstants.userKey(userId, AppConstants.keyCurrentBusinessId));
    
    if (businessId == null) return;

    final roles = await ref.read(userManagementRepositoryProvider).getRoles(businessId);
    final role = roles.firstWhere((r) => r.id == user.roleId, orElse: () => roles.first);
    state = state.copyWith(currentRole: role);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      
      // 1. Try Staff login first (manual check to avoid circular dependency at provider level)
      final storage = ref.read(localStorageServiceProvider);
      final owner = repo.getUser(); // Get primary owner data to find their businesses
      
      if (owner != null) {
        final businessDatasource = LocalBusinessDatasource(storage, owner.email);
        final businessRepo = BusinessRepository(businessDatasource);
        final userMgmtRepo = ref.read(userManagementRepositoryProvider);
        
        final businesses = businessRepo.getBusinesses();
        UserModel? staffUser;
        String? staffBusinessId;

        for (final business in businesses) {
          final users = await userMgmtRepo.getUsers(business.id);
          final found = users.firstWhere(
            (u) => u.email == email && u.password == password && u.isActive,
            orElse: () => UserModel(fullName: '', email: '', phone: '', password: ''),
          );
          if (found.email.isNotEmpty) {
            staffUser = found;
            staffBusinessId = business.id;
            break;
          }
        }

        if (staffUser != null) {
          // Log in as staff
          await repo.setAsLoggedInUser(staffUser);
          
          // Important: We need to set the current business for the staff session
          // This will ensure the app opens the correct business context
          await businessDatasource.setCurrentBusinessId(staffBusinessId!);
          
          state = state.copyWith(user: staffUser, isLoggedIn: true, isLoading: false);
          await _loadRoleForUser(staffUser);
          return;
        }
      }

      // 2. Try primary owner login
      final success = await repo.login(email, password);
      if (success) {
        final user = repo.getUser();
        state = state.copyWith(user: user, isLoggedIn: true, isLoading: false);
        if (user != null) await _loadRoleForUser(user);
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid email or password');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register(UserModel user) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.register(user);
      state = state.copyWith(user: user, isLoggedIn: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      
      // 1. Update the currently logged in user info in local storage
      await repo.setAsLoggedInUser(updatedUser);
      
      // 2. If the user is staff, we also need to update the record in the owner's user management list
      if (updatedUser.businessOwnerId != null) {
        final storage = ref.read(localStorageServiceProvider);
        final businessId = storage.getString(AppConstants.userKey(updatedUser.businessOwnerId!, AppConstants.keyCurrentBusinessId));
        if (businessId != null) {
          final userMgmtRepo = ref.read(userManagementRepositoryProvider);
          final users = await userMgmtRepo.getUsers(businessId);
          final updatedUsers = users.map((u) => u.email == updatedUser.email ? updatedUser : u).toList();
          await userMgmtRepo.saveUsers(businessId, updatedUsers);
        }
      }
      
      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      throw e;
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
