import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:billify/core/constants/api_endpoints.dart';
import 'package:billify/core/constants/app_constants.dart';
import 'package:billify/data/models/user_model.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref);
});

class ApiService {
  final Ref _ref;
  late final Dio _dio;
  final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final storage = _ref.read(localStorageServiceProvider);

          // 1. Attach Auth Token
          final token = storage.getString(AppConstants.keyToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // 2. Attach Current Business ID
          // We get the current user first to resolve the correct key for storage
          final userJson = storage.getString(AppConstants.keyUserData);
          if (userJson != null) {
            try {
              final user = UserModel.fromJson(jsonDecode(userJson));
              final userId = user.businessOwnerId ?? user.email;

              // Get the current business ID using the user-scoped key
              final businessId = storage.getString(
                AppConstants.userKey(userId, AppConstants.keyCurrentBusinessId),
              );

              if (businessId != null && int.tryParse(businessId) != null) {
                options.headers['x-business-id'] = businessId;
              }
            } catch (e) {
              print("Error resolving business ID in ApiService: $e");
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i(
            "RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}",
          );
          return handler.next(response);
        },
        onError: (e, handler) {
          _logger.e(
            "ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}\n"
            "DATA: ${e.response?.data}",
          );
          if (e.response?.statusCode == 401) {
            _logger.w("Unauthorized access - 401");
          }
          return handler.next(e);
        },
      ),
    );

    // Add Detailed Request Logger
    _dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => _logger.d(obj),
      ),
    );
  }

  Dio get instance => _dio;

  // Helper methods
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.put(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }
}
