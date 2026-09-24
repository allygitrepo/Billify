import 'package:billify/core/errors/app_failure.dart';

/// Sealed class representing the reactive lifecycle states of a UI screen/feature
sealed class UIState<T> {
  const UIState();

  /// Helper getters for concise UI rendering checks
  bool get isInitial => this is UIInitial<T>;
  bool get isLoading => this is UILoading<T>;
  bool get isSuccess => this is UISuccess<T>;
  bool get isFailure => this is UIFailure<T>;

  /// Safely extracts data if in Success state, else returns null
  T? get dataOrNull => this is UISuccess<T> ? (this as UISuccess<T>).data : null;

  /// Safely extracts failure if in Failure state, else returns null
  AppFailure? get failureOrNull => this is UIFailure<T> ? (this as UIFailure<T>).failure : null;

  /// Pattern matching helper method
  R when<R>({
    required R Function() initial,
    required R Function(String? message) loading,
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    if (this is UIInitial<T>) {
      return initial();
    } else if (this is UILoading<T>) {
      return loading((this as UILoading<T>).message);
    } else if (this is UISuccess<T>) {
      return success((this as UISuccess<T>).data);
    } else if (this is UIFailure<T>) {
      return failure((this as UIFailure<T>).failure);
    }
    throw StateError('Unhandled UIState subtype: $runtimeType');
  }

  /// Pattern matching with optional/fallback handlers
  R maybeWhen<R>({
    R Function()? initial,
    R Function(String? message)? loading,
    R Function(T data)? success,
    R Function(AppFailure failure)? failure,
    required R Function() orElse,
  }) {
    if (this is UIInitial<T> && initial != null) {
      return initial();
    } else if (this is UILoading<T> && loading != null) {
      return loading((this as UILoading<T>).message);
    } else if (this is UISuccess<T> && success != null) {
      return success((this as UISuccess<T>).data);
    } else if (this is UIFailure<T> && failure != null) {
      return failure((this as UIFailure<T>).failure);
    }
    return orElse();
  }
}

/// Initial uninitialized state
class UIInitial<T> extends UIState<T> {
  const UIInitial();
}

/// Asynchronous loading state with optional status message
class UILoading<T> extends UIState<T> {
  final String? message;
  final T? previousData;

  const UILoading({this.message, this.previousData});
}

/// Successful state holding strongly typed domain payload
class UISuccess<T> extends UIState<T> {
  final T data;

  const UISuccess(this.data);
}

/// Failure state holding strongly typed AppFailure
class UIFailure<T> extends UIState<T> {
  final AppFailure failure;
  final T? fallbackData;

  const UIFailure(this.failure, {this.fallbackData});
}
