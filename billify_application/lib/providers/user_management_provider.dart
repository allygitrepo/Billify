import 'package:billify_application/data/models/role_model.dart';
import 'package:billify_application/data/models/user_model.dart';
import 'package:billify_application/data/models/user_permission.dart';
import 'package:billify_application/data/repositories/user_management_repository.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return UserManagementRepository(storage);
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

  UserManagementNotifier(this._repo, this._businessId) : super(UserManagementState()) {
    if (_businessId != null) {
      loadData();
    }
  }

  Future<void> loadData() async {
    if (_businessId == null) return;
    state = state.copyWith(isLoading: true);
    final roles = await _repo.getRoles(_businessId);
    final users = await _repo.getUsers(_businessId);
    
    // If no roles exist, create default Admin role
    if (roles.isEmpty) {
      final adminRole = RoleModel(
        id: 'admin',
        name: 'Admin',
        permissions: {
          for (var module in PermissionModule.values)
            module: [PermissionAction.all]
        },
      );
      await _repo.saveRoles(_businessId, [adminRole]);
      state = state.copyWith(roles: [adminRole], users: users, isLoading: false);
    } else {
      state = state.copyWith(roles: roles, users: users, isLoading: false);
    }
  }

  Future<void> addRole(RoleModel role) async {
    if (_businessId == null) return;
    final newRoles = [...state.roles, role];
    await _repo.saveRoles(_businessId, newRoles);
    state = state.copyWith(roles: newRoles);
  }

  Future<void> updateRole(RoleModel role) async {
    if (_businessId == null) return;
    final newRoles = state.roles.map((e) => e.id == role.id ? role : e).toList();
    await _repo.saveRoles(_businessId, newRoles);
    state = state.copyWith(roles: newRoles);
  }

  Future<void> addUser(UserModel user) async {
    if (_businessId == null) return;
    final newUsers = [...state.users, user];
    await _repo.saveUsers(_businessId, newUsers);
    state = state.copyWith(users: newUsers);
  }

  Future<void> updateUser(UserModel user) async {
    if (_businessId == null) return;
    final newUsers = state.users.map((e) => e.email == user.email ? user : e).toList();
    await _repo.saveUsers(_businessId, newUsers);
    state = state.copyWith(users: newUsers);
  }
}

final userManagementProvider = StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  final repo = ref.watch(userManagementRepositoryProvider);
  final businessId = ref.watch(businessProvider).currentBusinessId;
  return UserManagementNotifier(repo, businessId);
});
