import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/food_item.dart';
import '../../../../shared/services/api_service.dart';

/// Browse data source provider.
final browseRepositoryProvider = Provider<BrowseRepository>((ref) {
  return BrowseRepository(ref.read(apiServiceProvider));
});

/// Repository for user-facing food item browsing.
class BrowseRepository {
  BrowseRepository(this._dio);
  final Dio _dio;

  /// GET /food-items (with optional filters, pagination).
  Future<ApiResult<({List<FoodItem> items, Map<String, dynamic> meta})>>
  getFoodItems({
    double? lat,
    double? lng,
    int? radius,
    int? merchantId,
    String? category,
    String? search,
    String? sortBy,
    int page = 1,
  }) async {
    return ApiResult.guard(() async {
      final response = await _dio.get(
        ApiEndpoints.foodItems,
        queryParameters: {
          'lat': ?lat,
          'lng': ?lng,
          'radius': ?radius,
          'merchant_id': ?merchantId,
          'category': ?category,
          if (search != null && search.isNotEmpty) 'search': search,
          'sort_by': ?sortBy,
          'page': page,
        },
      );
      final data = response.data;
      final items = (data['data'] as List)
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = data['meta'] as Map<String, dynamic>? ?? {};
      return (items: items, meta: meta);
    });
  }

  /// GET /food-items/:id
  Future<ApiResult<FoodItem>> getFoodItemDetail(int id) async {
    return ApiResult.guard(() async {
      final response = await _dio.get(ApiEndpoints.foodItem(id));
      return FoodItem.fromJson(response.data['data']);
    });
  }

  /// GET /food-items/flash-sale
  Future<ApiResult<List<FoodItem>>> getFlashSaleItems() async {
    return ApiResult.guard(() async {
      final response = await _dio.get(ApiEndpoints.flashSale);
      return (response.data['data'] as List)
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// GET /merchants/:id (public profile)
  Future<ApiResult<Map<String, dynamic>>> getMerchantProfile(int id) async {
    return ApiResult.guard(() async {
      final response = await _dio.get(ApiEndpoints.merchantProfile(id));
      return response.data['data'] as Map<String, dynamic>;
    });
  }

  /// GET /merchants/:id/reviews — merchant review list.
  Future<
    ApiResult<({List<Map<String, dynamic>> reviews, Map<String, dynamic> meta})>
  >
  getMerchantReviews(int merchantId, {int page = 1}) async {
    return ApiResult.guard(() async {
      final response = await _dio.get(
        ApiEndpoints.merchantReviews(merchantId),
        queryParameters: {'page': page},
      );
      final data = response.data;
      final reviews = (data['data'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final meta = data['meta'] as Map<String, dynamic>? ?? {};
      return (reviews: reviews, meta: meta);
    });
  }
}
