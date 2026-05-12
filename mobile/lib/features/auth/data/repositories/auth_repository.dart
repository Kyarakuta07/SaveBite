import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/services/api_service.dart';

/// Auth data source — raw API interaction.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.read(apiServiceProvider),
    storage: ref.read(storageServiceProvider),
  );
});

/// Repository that handles auth API calls and token persistence.
class AuthRepository {
  AuthRepository({required Dio dio, required FlutterSecureStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  /// POST /auth/register
  Future<ApiResult<User>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    return ApiResult.guard(() async {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      final body = response.data['data'];
      await _storage.write(key: _tokenKey, value: body['token']);
      return User.fromJson(body['user']);
    });
  }

  /// POST /auth/login
  Future<ApiResult<User>> login({
    required String email,
    required String password,
  }) async {
    return ApiResult.guard(() async {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final body = response.data['data'];
      await _storage.write(key: _tokenKey, value: body['token']);
      return User.fromJson(body['user']);
    });
  }

  /// POST /auth/logout
  Future<ApiResult<void>> logout() async {
    return ApiResult.guard(() async {
      await _dio.post(ApiEndpoints.logout);
      await _storage.deleteAll();
    });
  }

  /// GET /auth/me
  Future<ApiResult<User>> me() async {
    return ApiResult.guard(() async {
      final response = await _dio.get(ApiEndpoints.me);
      return User.fromJson(response.data['data']);
    });
  }

  /// PUT /auth/me/password
  Future<ApiResult<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    return ApiResult.guard(() async {
      await _dio.put(ApiEndpoints.updatePassword, data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmation,
      });
    });
  }

  /// PUT /auth/me/fcm-token
  Future<ApiResult<void>> updateFcmToken(String fcmToken) async {
    return ApiResult.guard(() async {
      await _dio.put(ApiEndpoints.updateFcmToken, data: {
        'fcm_token': fcmToken,
      });
    });
  }

  /// PUT /auth/me (multipart — name, phone, avatar)
  Future<ApiResult<User>> updateProfile({
    String? name,
    String? phone,
    String? avatarPath,
  }) async {
    return ApiResult.guard(() async {
      final avatar = avatarPath != null
          ? await MultipartFile.fromFile(avatarPath)
          : null;
      final formData = FormData.fromMap({
        'name': ?name,
        'phone': ?phone,
        'avatar': ?avatar,
      });
      final response = await _dio.put(
        ApiEndpoints.updateProfile,
        data: formData,
      );
      return User.fromJson(response.data['data']);
    });
  }

  /// Check if token exists (for splash screen).
  Future<String?> getStoredToken() async {
    return _storage.read(key: _tokenKey);
  }
}
