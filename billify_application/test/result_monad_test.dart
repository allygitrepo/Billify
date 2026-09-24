import 'package:billify/core/errors/app_failure.dart';
import 'package:billify/core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result Monad & AppFailure Comprehensive Tests', () {
    test('Result.success holds data and supports mapping', () {
      final Result<int, AppFailure> result = Result.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, equals(42));
      expect(result.failureOrNull, isNull);

      final mapped = result.map((value) => 'Value is $value');
      expect(mapped.dataOrNull, equals('Value is 42'));
    });

    test('Result.failure holds failure and skips mapping', () {
      const failure = NetworkFailure(message: 'No internet connection');
      final Result<int, AppFailure> result = Result.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, equals(failure));

      final mapped = result.map((value) => 'Value is $value');
      expect(mapped.isFailure, isTrue);
      expect(mapped.failureOrNull, equals(failure));
    });

    test('Result.flatMap chains successful operations', () {
      Result<int, AppFailure> divide(int a, int b) {
        if (b == 0) return const Result.failure(ValidationFailure(message: 'Cannot divide by zero'));
        return Result.success(a ~/ b);
      }

      final successChain = Result<int, AppFailure>.success(100)
          .flatMap((n) => divide(n, 2))
          .flatMap((n) => divide(n, 5));

      expect(successChain.dataOrNull, equals(10));

      final failChain = Result<int, AppFailure>.success(100)
          .flatMap((n) => divide(n, 0))
          .flatMap((n) => divide(n, 5));

      expect(failChain.isFailure, isTrue);
      expect(failChain.failureOrNull?.message, equals('Cannot divide by zero'));
    });

    test('Result.fold executes appropriate callbacks', () {
      const Result<String, AppFailure> success = Result.success('Billify POS');
      final successResult = success.fold(
        onSuccess: (data) => 'Success: $data',
        onFailure: (err) => 'Error: ${err.message}',
      );
      expect(successResult, equals('Success: Billify POS'));

      const Result<String, AppFailure> failure = Result.failure(AuthFailure(message: 'Session expired'));
      final failureResult = failure.fold(
        onSuccess: (data) => 'Success: $data',
        onFailure: (err) => 'Error: ${err.message}',
      );
      expect(failureResult, equals('Error: Session expired'));
    });

    test('AppFailure subclasses maintain distinct error identities', () {
      const serverErr = ServerFailure(message: 'Internal error 500', statusCode: 500);
      expect(serverErr.statusCode, equals(500));

      const authErr = AuthFailure(message: 'Unauthorized');
      expect(authErr.message, equals('Unauthorized'));

      const notFoundErr = NotFoundFailure(message: 'Product not found');
      expect(notFoundErr.message, equals('Product not found'));
    });
  });
}
