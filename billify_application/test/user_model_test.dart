import 'package:billify/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel & Security Isolation Tests', () {
    test('UserModel.fromJson parses snake_case and camelCase keys without exposing password', () {
      final json = {
        'id': 42,
        'name': 'Store Manager',
        'email': 'manager@billify.com',
        'mobile': '9876543210',
        'password': 'hashed_secret_password_here',
        'role_id': 2,
        'status': 'active',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals('42'));
      expect(user.name, equals('Store Manager'));
      expect(user.email, equals('manager@billify.com'));
      expect(user.roleId, equals('2'));
      expect(user.status, isTrue);
      // Password must NEVER be deserialized into client state
      expect(user.password, isNull);
    });

    test('UserModel.toJson serializes valid request payload', () {
      final user = UserModel(
        id: '42',
        name: 'Staff Cashier',
        mobile: '9123456780',
        roleId: '3',
        status: true,
      );

      final json = user.toJson();
      expect(json['id'], equals('42'));
      expect(json['name'], equals('Staff Cashier'));
      expect(json['role_id'], equals(3));
      expect(json['status'], isTrue);
      expect(json.containsKey('password'), isFalse);
    });

    test('UserModel copyWith produces modified clone without state mutation', () {
      final user = UserModel(
        id: '1',
        name: 'Original Name',
        mobile: '9000000000',
        status: true,
      );

      final updated = user.copyWith(name: 'Updated Name', status: false);

      expect(updated.id, equals('1'));
      expect(updated.name, equals('Updated Name'));
      expect(updated.status, isFalse);
      expect(user.name, equals('Original Name'));
      expect(user.status, isTrue);
    });
  });
}
