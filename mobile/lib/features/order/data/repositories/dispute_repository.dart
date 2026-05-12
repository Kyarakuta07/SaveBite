import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/services/api_service.dart';

/// Dispute data source provider.
final disputeRepositoryProvider = Provider<DisputeRepository>((ref) {
  return DisputeRepository(ref.read(apiServiceProvider));
});

/// Repository for user dispute operations.
class DisputeRepository {
  DisputeRepository(this._dio);
  final Dio _dio;

  /// POST /orders/:id/dispute — file a dispute (multipart: photo + video required).
  Future<ApiResult<Map<String, dynamic>>> createDispute({
    required int orderId,
    required String reason,
    required String photoPath,
    required String videoPath,
  }) async {
    return ApiResult.guard(() async {
      final formData = FormData.fromMap({
        'reason': reason,
        'photo_proof': await MultipartFile.fromFile(photoPath),
        'video_proof': await MultipartFile.fromFile(videoPath),
      });
      final response = await _dio.post(
        ApiEndpoints.createDispute(orderId),
        data: formData,
      );
      return response.data['data'] as Map<String, dynamic>;
    });
  }

  /// GET /disputes/:id — check dispute status.
  Future<ApiResult<Map<String, dynamic>>> getDispute(int disputeId) async {
    return ApiResult.guard(() async {
      final response = await _dio.get(ApiEndpoints.dispute(disputeId));
      return response.data['data'] as Map<String, dynamic>;
    });
  }
}
