import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/services/api_service.dart';

/// Order data source provider.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.read(apiServiceProvider));
});

/// Repository for user-facing order operations.
class OrderRepository {
  OrderRepository(this._dio);
  final Dio _dio;

  /// POST /orders — create new order (checkout).
  Future<ApiResult<Map<String, dynamic>>> createOrder({
    required int merchantId,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    String? notes,
  }) async {
    return ApiResult.guard(() async {
      final response = await _dio.post(ApiEndpoints.orders, data: {
        'merchant_id': merchantId,
        'items': items,
        'payment_method': paymentMethod,
        'delivery_address': deliveryAddress,
        'delivery_lat': deliveryLat,
        'delivery_lng': deliveryLng,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      return response.data['data'] as Map<String, dynamic>;
    });
  }

  /// GET /orders — order history (paginated).
  Future<ApiResult<({List<Order> orders, Map<String, dynamic> meta})>>
      getOrders({int page = 1}) async {
    return ApiResult.guard(() async {
      final response = await _dio.get(
        ApiEndpoints.orders,
        queryParameters: {'page': page},
      );
      final data = response.data;
      final orders = (data['data'] as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = data['meta'] as Map<String, dynamic>? ?? {};
      return (orders: orders, meta: meta);
    });
  }

  /// GET /orders/:id — order detail.
  Future<ApiResult<Order>> getOrderDetail(int id) async {
    return ApiResult.guard(() async {
      final response = await _dio.get(ApiEndpoints.order(id));
      return Order.fromJson(response.data['data']);
    });
  }

  /// POST /orders/:id/complete — confirm order received.
  Future<ApiResult<void>> completeOrder(int id) async {
    return ApiResult.guard(() async {
      await _dio.post(ApiEndpoints.orderComplete(id));
    });
  }

  /// POST /orders/:id/cancel — cancel order.
  Future<ApiResult<void>> cancelOrder(int id) async {
    return ApiResult.guard(() async {
      await _dio.post(ApiEndpoints.orderCancel(id));
    });
  }

  /// POST /orders/:id/reorder — clone previous order items.
  Future<ApiResult<Map<String, dynamic>>> reorder(int id) async {
    return ApiResult.guard(() async {
      final response = await _dio.post(ApiEndpoints.orderReorder(id));
      return response.data['data'] as Map<String, dynamic>;
    });
  }

  /// POST /orders/:id/review — create review.
  Future<ApiResult<void>> createReview({
    required int orderId,
    required int rating,
    String? comment,
    bool isAnonymous = false,
  }) async {
    return ApiResult.guard(() async {
      await _dio.post(ApiEndpoints.createReview(orderId), data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        'is_anonymous': isAnonymous,
      });
    });
  }

  /// GET /orders/:id/delivery — delivery tracking.
  Future<ApiResult<Map<String, dynamic>>> getDelivery(int orderId) async {
    return ApiResult.guard(() async {
      final response = await _dio.get(ApiEndpoints.delivery(orderId));
      return response.data['data'] as Map<String, dynamic>;
    });
  }

  /// POST /orders/:id/self-pickup — user opts for self-pickup.
  Future<ApiResult<void>> selfPickup(int orderId) async {
    return ApiResult.guard(() async {
      await _dio.post(ApiEndpoints.selfPickup(orderId));
    });
  }
}
