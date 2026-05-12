import 'package:equatable/equatable.dart';

import '../../core/utils/safe_parse.dart';

/// Order entity matching backend API response.
class Order extends Equatable {
  const Order({
    required this.id,
    required this.orderCode,
    required this.subtotal,
    required this.deliveryFee,
    required this.commissionFee,
    required this.totalAmount,
    required this.savingsAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.notes,
    this.items = const [],
    this.merchant,
    this.review,
    this.delivery,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String orderCode;
  final String subtotal;
  final String deliveryFee;
  final String commissionFee;
  final String totalAmount;
  final String savingsAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? notes;
  final List<OrderItem> items;
  final Map<String, dynamic>? merchant;
  final Map<String, dynamic>? review;
  final Map<String, dynamic>? delivery;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Whether user can cancel (only confirmed, before pickup).
  bool get canCancel => orderStatus == 'confirmed';

  /// Whether user can complete (only delivered).
  bool get canComplete => orderStatus == 'delivered';

  /// Whether user can review (completed, no existing review).
  bool get canReview => orderStatus == 'completed' && review == null;

  /// Whether user can dispute (delivered, within 60-min window).
  bool get canDispute => orderStatus == 'delivered';

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: toInt(json['id']),
        orderCode: json['order_code'] as String? ?? '',
        subtotal: (json['subtotal'] ?? '0').toString(),
        deliveryFee: (json['delivery_fee'] ?? '0').toString(),
        commissionFee: (json['commission_fee'] ?? '0').toString(),
        totalAmount: (json['total_amount'] ?? '0').toString(),
        savingsAmount: (json['savings_amount'] ?? '0').toString(),
        paymentMethod: json['payment_method'] as String? ?? 'wallet',
        paymentStatus: json['payment_status'] as String? ?? 'pending',
        orderStatus: json['order_status'] as String? ?? 'pending',
        deliveryAddress: json['delivery_address'] as String?,
        deliveryLat: toDoubleOrNull(json['delivery_lat']),
        deliveryLng: toDoubleOrNull(json['delivery_lng']),
        notes: json['notes'] as String?,
        items: (json['items'] as List?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        merchant: json['merchant'] as Map<String, dynamic>?,
        review: json['review'] as Map<String, dynamic>?,
        delivery: json['delivery'] as Map<String, dynamic>?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );

  @override
  List<Object?> get props => [id, orderCode, orderStatus];
}

/// Single item in an order.
class OrderItem extends Equatable {
  const OrderItem({
    required this.id,
    required this.foodItemId,
    required this.name,
    required this.quantity,
    required this.price,
    this.image,
  });

  final int id;
  final int foodItemId;
  final String name;
  final int quantity;
  final String price;
  final String? image;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: toInt(json['id']),
        foodItemId: toInt(json['food_item_id']),
        name: json['food_name'] as String? ?? json['name'] as String? ?? '',
        quantity: toInt(json['quantity'], 1),
        price: (json['rescue_price'] ?? json['line_total'] ?? json['price'] ?? '0').toString(),
        image: json['image'] as String?,
      );

  @override
  List<Object?> get props => [id, foodItemId];
}
