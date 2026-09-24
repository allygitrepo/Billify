import 'package:billify/core/errors/app_failure.dart';

/// Sealed functional Result type representing either a [Success] or a [Failure]
sealed class Result<T, E extends AppFailure> {
  const Result();

  /// True if operation succeeded and holds valid domain payload
  bool get isSuccess => this is Success<T, E>;

  /// True if operation failed and holds an AppFailure
  bool get isFailure => this is Failure<T, E>;

  /// Safely extracts data if success, else null
  T? get dataOrNull => isSuccess ? (this as Success<T, E>).data : null;

  /// Safely extracts failure if failure, else null
  E? get failureOrNull => isFailure ? (this as Failure<T, E>).failure : null;

  /// Pattern match on the Result
  R when<R>({
    required R Function(T data) success,
    required R Function(E failure) failure,
  }) {
    if (this is Success<T, E>) {
      return success((this as Success<T, E>).data);
    } else if (this is Failure<T, E>) {
      return failure((this as Failure<T, E>).failure);
    }
    throw StateError('Unhandled Result subtype: $runtimeType');
  }

  /// Transform the success value while preserving the failure
  Result<R, E> map<R>(R Function(T data) transform) {
    if (this is Success<T, E>) {
      return Success(transform((this as Success<T, E>).data));
    }
    return Failure((this as Failure<T, E>).failure);
  }

  /// Transform the failure while preserving the success
  Result<T, R> mapFailure<R extends AppFailure>(R Function(E failure) transform) {
    if (this is Failure<T, E>) {
      return Failure(transform((this as Failure<T, E>).failure));
    }
    return Success((this as Success<T, E>).data);
  }
}

/// Represents a successful computation returning [data]
class Success<T, E extends AppFailure> extends Result<T, E> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success(data: $data)';
}

/// Represents a failed computation returning [failure]
class Failure<T, E extends AppFailure> extends Result<T, E> {
  final E failure;

  const Failure(this.failure);

  @override
  String toString() => 'Failure(failure: $failure)';
}
