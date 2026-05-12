import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/notification.dart';
import '../../../../shared/services/api_service.dart';

/// Social (follow/notification) data source provider.
final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(ref.read(apiServiceProvider));
});

/// Repository for follow/unfollow and notification operations.
class SocialRepository {
  SocialRepository(this._dio);
  final Dio _dio;

  // ─── Follow ────────────────────────────────

  /// POST /merchants/:id/follow — follow a merchant.
  Future<ApiResult<void>> followMerchant(int merchantId) async {
    return ApiResult.guard(() async {
      await _dio.post(ApiEndpoints.followMerchant(merchantId));
    });
  }

  /// DELETE /merchants/:id/follow — unfollow a merchant.
  Future<ApiResult<void>> unfollowMerchant(int merchantId) async {
    return ApiResult.guard(() async {
      await _dio.delete(ApiEndpoints.followMerchant(merchantId));
    });
  }

  /// GET /me/follows — list followed merchants.
  Future<ApiResult<List<Map<String, dynamic>>>> getFollows() async {
    return ApiResult.guard(() async {
      final response = await _dio.get(ApiEndpoints.follows);
      return (response.data['data'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    });
  }

  // ─── Notifications ─────────────────────────

  /// GET /me/notifications — paginated notification list.
  Future<ApiResult<({List<AppNotification> notifications, Map<String, dynamic> meta})>>
      getNotifications({int page = 1}) async {
    return ApiResult.guard(() async {
      final response = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page},
      );
      final data = response.data;
      final notifs = (data['data'] as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = data['meta'] as Map<String, dynamic>? ?? {};
      return (notifications: notifs, meta: meta);
    });
  }

  /// POST /me/notifications/read-all — mark all as read.
  Future<ApiResult<void>> readAllNotifications() async {
    return ApiResult.guard(() async {
      await _dio.post(ApiEndpoints.readAllNotifications);
    });
  }
}
