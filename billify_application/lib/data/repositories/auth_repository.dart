import 'package:billify_application/data/datasources/auth_datasource.dart';
import 'package:billify_application/data/models/user_model.dart';

class AuthRepository {
  final AuthDatasource _datasource;

  AuthRepository(this._datasource);

  Future<bool> register(UserModel user) async {
    return await _datasource.register(user);
  }

  Future<bool> login(String email, String password) async {
    return await _datasource.login(email, password);
  }

  Future<void> logout() async {
    await _datasource.logout();
  }

  UserModel? getUser() {
    return _datasource.getUser();
  }

  bool isLoggedIn() {
    return _datasource.isLoggedIn();
  }
}
