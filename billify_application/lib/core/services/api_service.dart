import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:billify/core/constants/api_endpoints.dart';
import 'package:billify/core/constants/app_constants.dart';
import 'package:billify/core/errors/app_exception.dart';
import 'package:billify/core/utils/app_logger.dart';
import 'package:billify/data/models/user_model.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref);
});

class ApiService {
  final Ref _ref;
  late final Dio _dio;

  ApiService(this._ref) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Attach Auth & Context Interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final storage = _ref.read(localStorageServiceProvider);

          // 1. Attach Auth Token
          final token = storage.getString(AppConstants.keyToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // 2. Attach Current Business ID
          final userJson = storage.getString(AppConstants.keyUserData);
          if (userJson != null) {
            try {
              final user = UserModel.fromJson(jsonDecode(userJson));
              final userId = (user.businessOwnerId?.isNotEmpty == true)
                  ? user.businessOwnerId!
                  : (user.email?.isNotEmpty == true)
                      ? user.email!
                      : user.mobile;

              final businessId = storage.getString(
                AppConstants.userKey(userId, AppConstants.keyCurrentBusinessId),
              );

              if (businessId != null && int.tryParse(businessId) != null) {
                options.headers['x-business-id'] = businessId;
              }
            } catch (e) {
              AppLogger.warning('Error resolving business ID for request: $e', tag: 'ApiService');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.debug(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
            tag: 'ApiService',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          AppLogger.error(
            'HTTP ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}',
            tag: 'ApiService',
            error: e.response?.data ?? e.message,
          );

          // Global 401 Unauthorized handling (Session Expiration)
          if (e.response?.statusCode == 401) {
            AppLogger.warning('Session expired (401). Clearing auth session.', tag: 'ApiService');
            try {
              // Trigger clean logout
              await _ref.read(authProvider.notifier).logout();
            } catch (err) {
              AppLogger.error('Failed to trigger auto-logout on 401: $err', tag: 'ApiService');
            }
          }

          return handler.next(e);
        },
      ),
    );

    // Attach request/response debug logger in development only
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }
  }

  Dio get instance => _dio;

  // Strongly typed HTTP Helper methods that translate DioExceptions to AppExceptions
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options,
      );
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options,
      );
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }

  /// Uploads multipart form data (e.g. photos, documents, receipts)
  Future<Response> uploadFormData(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }
}
