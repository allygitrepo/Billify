import 'package:billify/data/datasources/remote_user_management_datasource.dart';
import 'package:billify/data/models/role_model.dart';
import 'package:billify/data/models/user_model.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:billify/data/repositories/user_management_repository.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final userManagementRepositoryProvider = Provider<UserManagementRepository>((
  ref,
) {
  final storage = ref.watch(localStorageServiceProvider);
  final remote = ref.watch(remoteUserManagementDatasourceProvider);
  return UserManagementRepository(storage, remote);
});

class UserManagementState {
  final List<UserModel> users;
  final List<RoleModel> roles;
  final bool isLoading;

  UserManagementState({
    this.users = const [],
    this.roles = const [],
    this.isLoading = false,
  });

  UserManagementState copyWith({
    List<UserModel>? users,
    List<RoleModel>? roles,
    bool? isLoading,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final UserManagementRepository _repo;
  final String? _businessId;

  UserManagementNotifier(this._repo, this._businessId)
    : super(UserManagementState()) {
    if (_businessId != null) {
      loadData();
    }
  }

  Future<void> loadData() async {
    if (_businessId == null) return;
    state = state.copyWith(isLoading: true);

    // Load local first for speed
    final localRoles = await _repo.getRoles(_businessId);
    final localUsers = await _repo.getUsers(_businessId);
    state = state.copyWith(
      roles: localRoles,
      users: localUsers,
      isLoading: localRoles.isEmpty,
    );

    // Sync from remote in background
    await _repo.syncAll(_businessId);

    final roles = await _repo.getRoles(_businessId);
    final users = await _repo.getUsers(_businessId);

    // If no roles exist after sync, create default Admin role locallay (fallback)
    // but in a production app, the backend should provide default roles.
    if (roles.isEmpty) {
      final adminRole = RoleModel(
        id: 'admin',
        name: 'Admin',
        permissions: {
          for (var module in PermissionModule.values)
            module: [PermissionAction.all],
        },
      );
      state = state.copyWith(
        roles: [adminRole],
        users: users,
        isLoading: false,
      );
    } else {
      state = state.copyWith(roles: roles, users: users, isLoading: false);
    }
  }

  Future<void> addRole(RoleModel role) async {
    if (_businessId == null) return;
    state = state.copyWith(isLoading: true);
    final newRole = await _repo.addRole(_businessId, role);
    if (newRole != null) {
      state = state.copyWith(
        roles: [...state.roles, newRole],
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateRole(RoleModel role) async {
    if (_businessId == null) return;
    state = state.copyWith(isLoading: true);
    final success = await _repo.updateRole(_businessId, role);
    if (success) {
      final newRoles = state.roles
          .map((e) => e.id == role.id ? role : e)
          .toList();
      state = state.copyWith(roles: newRoles, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addUser(UserModel user) async {
    if (_businessId == null) return;
    state = state.copyWith(isLoading: true);
    final newUser = await _repo.addUser(_businessId, user);
    if (newUser != null) {
      state = state.copyWith(
        users: [...state.users, newUser],
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateUser(UserModel user) async {
    if (_businessId == null || user.id == null) return;
    state = state.copyWith(isLoading: true);
    final success = await _repo.updateUser(_businessId, user);
    if (success) {
      final newUsers = state.users
          .map((e) => e.id == user.id ? user : e)
          .toList();
      state = state.copyWith(users: newUsers, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteUser(String userId) async {
    if (_businessId == null) return;
    state = state.copyWith(isLoading: true);
    final success = await _repo.deleteUser(_businessId, userId);
    if (success) {
      final newUsers = state.users.where((u) => u.id != userId).toList();
      state = state.copyWith(users: newUsers, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }
}

final userManagementProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
      final repo = ref.watch(userManagementRepositoryProvider);
      final businessId = ref.watch(businessProvider).currentBusinessId;
      return UserManagementNotifier(repo, businessId);
    });
