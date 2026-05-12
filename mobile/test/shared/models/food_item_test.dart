import 'package:flutter_test/flutter_test.dart';
import 'package:savebite/shared/models/food_item.dart';

void main() {
  group('FoodItem.fromJson', () {
    test('parses complete food item JSON', () {
      final json = {
        'id': 101,
        'name': 'Roti Coklat',
        'description': 'Roti coklat sisa stok hari ini',
        'image': 'https://example.com/roti.jpg',
        'original_price': '25000',
        'rescue_price': '12500',
        'discount_pct': 50,
        'quantity': 10,
        'quantity_sold': 3,
        'reason': 'Mendekati tanggal kadaluwarsa',
        'produced_at': '2026-05-06T08:00:00.000Z',
        'expires_at': '2026-05-08T23:59:00.000Z',
        'status': 'available',
        'pickup_only': false,
        'is_flash_sale': true,
        'flash_sale_ends_at': '2026-05-08T18:00:00.000Z',
        'seconds_remaining': 3600,
        'merchant': {
          'id': 10,
          'display_name': 'Toko Roti Makmur',
          'is_anonymous': false,
          'category': 'bakery',
          'average_rating': '4.50',
          'total_reviews': 42,
          'distance_km': 1.5,
          'logo': 'https://example.com/logo.jpg',
        },
      };

      final item = FoodItem.fromJson(json);

      expect(item.id, 101);
      expect(item.name, 'Roti Coklat');
      expect(item.description, 'Roti coklat sisa stok hari ini');
      expect(item.originalPrice, '25000');
      expect(item.rescuePrice, '12500');
      expect(item.discountPct, 50);
      expect(item.quantity, 10);
      expect(item.quantitySold, 3);
      expect(item.stockRemaining, 7);
      expect(item.status, 'available');
      expect(item.pickupOnly, false);
      expect(item.isFlashSale, true);
      expect(item.secondsRemaining, 3600);
      expect(item.merchant, isNotNull);
      expect(item.merchant!.displayName, 'Toko Roti Makmur');
      expect(item.merchant!.category, 'bakery');
      expect(item.producedAt, isNotNull);
      expect(item.expiresAt, isNotNull);
      expect(item.flashSaleEndsAt, isNotNull);
    });

    test('handles minimal JSON with defaults', () {
      final json = {
        'id': 102,
        'name': 'Nasi Goreng',
        'original_price': '15000',
        'rescue_price': '8000',
        'discount_pct': 47,
        'status': 'available',
      };

      final item = FoodItem.fromJson(json);
      expect(item.id, 102);
      expect(item.quantity, 0);
      expect(item.quantitySold, 0);
      expect(item.stockRemaining, 0);
      expect(item.pickupOnly, false);
      expect(item.isFlashSale, false);
      expect(item.secondsRemaining, isNull);
      expect(item.merchant, isNull);
    });

    test('handles price as numeric values (backend edge case)', () {
      final json = {
        'id': 103,
        'name': 'Test Item',
        'original_price': 30000,
        'rescue_price': 15000,
        'discount_pct': 50,
        'status': 'sold_out',
      };

      final item = FoodItem.fromJson(json);
      expect(item.originalPrice, '30000');
      expect(item.rescuePrice, '15000');
    });

    test('stockRemaining computed correctly', () {
      final json = {
        'id': 104,
        'name': 'Low Stock',
        'original_price': '10000',
        'rescue_price': '5000',
        'discount_pct': 50,
        'quantity': 5,
        'quantity_sold': 4,
        'status': 'available',
      };

      final item = FoodItem.fromJson(json);
      expect(item.stockRemaining, 1);
    });
  });

  group('MerchantSummary.fromJson', () {
    test('parses full merchant summary', () {
      final json = {
        'id': 10,
        'display_name': 'Bakery ABC',
        'is_anonymous': true,
        'category': 'bakery',
        'average_rating': '4.75',
        'total_reviews': 100,
        'distance_km': 2.3,
        'logo': 'https://example.com/logo.jpg',
        'address': 'Jl. Kebon Jeruk No.10',
        'operational_hours': {'mon': '08:00-22:00', 'tue': '08:00-22:00'},
        'latitude': -6.2,
        'longitude': 106.8,
      };

      final merchant = MerchantSummary.fromJson(json);
      expect(merchant.id, 10);
      expect(merchant.displayName, 'Bakery ABC');
      expect(merchant.isAnonymous, true);
      expect(merchant.category, 'bakery');
      expect(merchant.totalReviews, 100);
      expect(merchant.distanceKm, 2.3);
      expect(merchant.address, 'Jl. Kebon Jeruk No.10');
      expect(merchant.operationalHours, isNotNull);
      expect(merchant.latitude, -6.2);
      expect(merchant.longitude, 106.8);
    });

    test('handles minimal merchant (anonymous store)', () {
      final json = {
        'id': 20,
        'display_name': 'Mitra Hemat #12',
        'is_anonymous': true,
      };

      final merchant = MerchantSummary.fromJson(json);
      expect(merchant.id, 20);
      expect(merchant.isAnonymous, true);
      expect(merchant.category, isNull);
      expect(merchant.distanceKm, isNull);
      expect(merchant.logo, isNull);
    });
  });
}
