import 'package:billify_application/data/datasources/auth_datasource.dart';
import 'package:billify_application/data/models/user_model.dart';
import 'package:billify_application/data/repositories/auth_repository.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final datasource = LocalAuthDatasource(storage);
  return AuthRepository(datasource);
});

class AuthState {
  final UserModel? user;
  final bool isLoggedIn;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoggedIn = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoggedIn,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
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
    return AuthState(user: user, isLoggedIn: isLoggedIn);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final success = await repo.login(email, password);
      if (success) {
        final user = repo.getUser();
        state = state.copyWith(user: user, isLoggedIn: true, isLoading: false);
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

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
