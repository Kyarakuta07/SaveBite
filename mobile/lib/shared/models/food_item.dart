import 'package:equatable/equatable.dart';

import '../../core/utils/safe_parse.dart';

/// FoodItem entity matching browse/detail API responses.
class FoodItem extends Equatable {
  const FoodItem({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.originalPrice,
    required this.rescuePrice,
    required this.discountPct,
    required this.quantity,
    this.quantitySold = 0,
    this.reason,
    this.producedAt,
    this.expiresAt,
    required this.status,
    this.pickupOnly = false,
    this.isFlashSale = false,
    this.flashSaleEndsAt,
    this.secondsRemaining,
    this.merchant,
  });

  final int id;
  final String name;
  final String? description;
  final String? image;
  final String originalPrice;
  final String rescuePrice;
  final int discountPct;
  final int quantity;
  final int quantitySold;
  final String? reason;
  final DateTime? producedAt;
  final DateTime? expiresAt;
  final String status;
  final bool pickupOnly;
  final bool isFlashSale;
  final DateTime? flashSaleEndsAt;
  final int? secondsRemaining;
  final MerchantSummary? merchant;

  int get stockRemaining => quantity - quantitySold;

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: toInt(json['id']),
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        image: json['image'] as String?,
        originalPrice: (json['original_price'] ?? '0').toString(),
        rescuePrice: (json['rescue_price'] ?? '0').toString(),
        discountPct: toInt(json['discount_pct']),
        quantity: toInt(json['quantity']),
        quantitySold: toInt(json['quantity_sold']),
        reason: json['reason'] as String?,
        producedAt: json['produced_at'] != null
            ? DateTime.tryParse(json['produced_at'].toString())
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'].toString())
            : null,
        status: json['status'] as String? ?? 'available',
        pickupOnly: toBool(json['pickup_only']),
        isFlashSale: toBool(json['is_flash_sale']),
        flashSaleEndsAt: json['flash_sale_ends_at'] != null
            ? DateTime.tryParse(json['flash_sale_ends_at'].toString())
            : null,
        secondsRemaining: toIntOrNull(json['seconds_remaining']),
        merchant: json['merchant'] != null
            ? MerchantSummary.fromJson(
                json['merchant'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [id, name, status];
}

/// Embedded merchant info inside food item response.
class MerchantSummary extends Equatable {
  const MerchantSummary({
    required this.id,
    this.displayName,
    this.isAnonymous = false,
    this.category,
    this.averageRating,
    this.totalReviews,
    this.distanceKm,
    this.logo,
    this.address,
    this.operationalHours,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String? displayName;
  final bool isAnonymous;
  final String? category;
  final dynamic averageRating;
  final int? totalReviews;
  final double? distanceKm;
  final String? logo;
  final String? address;
  final Map<String, dynamic>? operationalHours;
  final double? latitude;
  final double? longitude;

  factory MerchantSummary.fromJson(Map<String, dynamic> json) =>
      MerchantSummary(
        id: toInt(json['id']),
        displayName: json['display_name'] as String?,
        isAnonymous: toBool(json['is_anonymous']),
        category: json['category'] as String?,
        averageRating: json['average_rating'],
        totalReviews: toIntOrNull(json['total_reviews']),
        distanceKm: toDoubleOrNull(json['distance_km']),
        logo: json['logo'] as String?,
        address: json['address'] as String?,
        operationalHours: json['operational_hours'] as Map<String, dynamic>?,
        latitude: toDoubleOrNull(json['latitude']),
        longitude: toDoubleOrNull(json['longitude']),
      );

  @override
  List<Object?> get props => [id, displayName];
}
