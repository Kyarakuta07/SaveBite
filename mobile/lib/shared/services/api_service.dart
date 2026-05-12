import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/app_env.dart';
import '../../core/constants/api_endpoints.dart';

/// Dio HTTP client provider with auth interceptor.
final apiServiceProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: ApiEndpoints.connectTimeout,
      receiveTimeout: ApiEndpoints.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        const storage = FlutterSecureStorage();
        final token = await storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          const storage = FlutterSecureStorage();
          await storage.deleteAll();
        }
        return handler.next(error);
      },
    ),
  );

  // Debug-only: request/response logging + environment info
  assert(() {
    debugPrint('┌─ SaveBite API ─────────────────────');
    debugPrint('│ ENV:  ${AppEnv.env}');
    debugPrint('│ URL:  ${ApiEndpoints.baseUrl}');
    debugPrint('└────────────────────────────────────');
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
    return true;
  }());

  return dio;
});

/// Secure storage provider for token persistence.
final storageServiceProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});
