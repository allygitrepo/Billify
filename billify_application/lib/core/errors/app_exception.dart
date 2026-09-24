import 'package:dio/dio.dart';
import 'package:billify/core/errors/app_failure.dart';

/// Base Exception class for custom application exceptions
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;

  /// Converts any Exception / DioException into a strongly typed AppFailure
  AppFailure toFailure() {
    if (statusCode == 401 || statusCode == 403) {
      return AuthFailure(message: message, statusCode: statusCode, cause: originalError);
    }
    if (statusCode != null && statusCode! >= 500) {
      return ServerFailure(message: message, statusCode: statusCode, cause: originalError);
    }
    if (statusCode == 422 || statusCode == 400) {
      return ValidationFailure(message: message, statusCode: statusCode, cause: originalError);
    }
    return ServerFailure(message: message, statusCode: statusCode, cause: originalError);
  }

  /// Factory constructor to map DioException into a typed AppException
  factory AppException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          message: 'Connection timed out. Please check your internet connection and try again.',
          statusCode: error.response?.statusCode ?? 408,
          originalError: error,
        );
      case DioExceptionType.connectionError:
        return AppException(
          message: 'Unable to connect to server. Please check your network.',
          statusCode: null,
          originalError: error,
        );
      case DioExceptionType.badResponse:
        final responseData = error.response?.data;
        String message = 'Server error occurred.';
        if (responseData is Map && responseData['message'] != null) {
          message = responseData['message'].toString();
        } else if (responseData is String && responseData.isNotEmpty) {
          message = responseData;
        } else {
          message = _mapStatusCodeToMessage(error.response?.statusCode);
        }
        return AppException(
          message: message,
          statusCode: error.response?.statusCode,
          originalError: error,
        );
      case DioExceptionType.cancel:
        return AppException(
          message: 'Request was cancelled.',
          originalError: error,
        );
      default:
        return AppException(
          message: 'A network error occurred. Please try again.',
          originalError: error,
        );
    }
  }

  static String _mapStatusCodeToMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request parameters.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Requested resource was not found.';
      case 408:
        return 'Request timeout. Please try again.';
      case 429:
        return 'Too many requests. Please wait a moment.';
      case 500:
      case 502:
      case 503:
        return 'Server is temporarily unavailable. Please try again later.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
