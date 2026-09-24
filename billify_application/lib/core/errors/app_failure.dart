/// Sealed class hierarchy representing all domain failures in the application
sealed class AppFailure {
  final String message;
  final int? statusCode;
  final dynamic cause;

  const AppFailure({
    required this.message,
    this.statusCode,
    this.cause,
  });

  @override
  String toString() => '$runtimeType(message: $message, statusCode: $statusCode)';
}

/// Network-related failures (timeouts, no internet, connection errors)
class NetworkFailure extends AppFailure {
  const NetworkFailure({
    String message = 'Unable to connect to server. Please check your internet connection.',
    super.statusCode,
    super.cause,
  }) : super(message: message);
}

/// Authentication and authorization failures (401, 403, invalid token)
class AuthFailure extends AppFailure {
  const AuthFailure({
    String message = 'Authentication failed or session expired. Please log in again.',
    super.statusCode = 401,
    super.cause,
  }) : super(message: message);
}

/// Server/API failures (500, 502, 503, invalid payload responses)
class ServerFailure extends AppFailure {
  const ServerFailure({
    required super.message,
    super.statusCode = 500,
    super.cause,
  });
}

/// Validation and input business rule failures (422, client-side validation errors)
class ValidationFailure extends AppFailure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
    super.statusCode = 422,
    super.cause,
  });
}

/// Not found resource failures (404)
class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    String message = 'The requested resource was not found.',
    super.statusCode = 404,
    super.cause,
  }) : super(message: message);
}

/// Local database or persistent storage failures
class CacheFailure extends AppFailure {
  const CacheFailure({
    String message = 'Failed to load or write local cached data.',
    super.cause,
  }) : super(message: message);
}

/// Unknown / unexpected application failures
class UnknownFailure extends AppFailure {
  const UnknownFailure({
    String message = 'An unexpected error occurred. Please try again.',
    super.cause,
  }) : super(message: message);
}
