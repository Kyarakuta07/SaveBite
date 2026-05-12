import 'package:flutter_test/flutter_test.dart';
import 'package:savebite/shared/models/order.dart';

void main() {
  group('Order.fromJson', () {
    test('parses complete order JSON', () {
      final json = {
        'id': 1,
        'order_code': 'SB-20260508-0001',
        'subtotal': '25000',
        'delivery_fee': '12000',
        'commission_fee': '1250',
        'total_amount': '37000',
        'savings_amount': '13000',
        'payment_method': 'wallet',
        'payment_status': 'paid',
        'order_status': 'delivered',
        'delivery_address': 'Jl. Test No. 1',
        'delivery_lat': -6.2,
        'delivery_lng': 106.8,
        'notes': 'Jangan pakai plastik',
        'items': [
          {
            'id': 1,
            'food_item_id': 101,
            'food_name': 'Roti Coklat',
            'quantity': 2,
            'rescue_price': '12500',
            'image': 'https://example.com/roti.jpg',
          },
        ],
        'merchant': {
          'id': 10,
          'display_name': 'Toko Roti Makmur',
          'category': 'bakery',
        },
        'review': null,
        'delivery': {
          'status': 'delivered',
          'driver_name': 'Budi',
          'driver_phone': '081234567890',
        },
        'created_at': '2026-05-08T10:00:00.000Z',
        'updated_at': '2026-05-08T12:00:00.000Z',
      };

      final order = Order.fromJson(json);

      expect(order.id, 1);
      expect(order.orderCode, 'SB-20260508-0001');
      expect(order.subtotal, '25000');
      expect(order.deliveryFee, '12000');
      expect(order.totalAmount, '37000');
      expect(order.savingsAmount, '13000');
      expect(order.paymentMethod, 'wallet');
      expect(order.paymentStatus, 'paid');
      expect(order.orderStatus, 'delivered');
      expect(order.deliveryAddress, 'Jl. Test No. 1');
      expect(order.notes, 'Jangan pakai plastik');
      expect(order.items, hasLength(1));
      expect(order.merchant, isNotNull);
      expect(order.review, isNull);
      expect(order.delivery, isNotNull);
      expect(order.createdAt, isNotNull);
    });

    test('handles minimal JSON with defaults', () {
      final json = {
        'id': 2,
        'order_code': 'SB-TEST-002',
        'subtotal': '10000',
        'delivery_fee': '0',
        'commission_fee': '500',
        'total_amount': '10000',
        'savings_amount': '5000',
        'payment_method': 'qris',
        'payment_status': 'pending',
        'order_status': 'pending',
      };

      final order = Order.fromJson(json);
      expect(order.items, isEmpty);
      expect(order.merchant, isNull);
      expect(order.delivery, isNull);
      expect(order.notes, isNull);
      expect(order.createdAt, isNull);
    });

    test('handles numeric amounts (backend edge case)', () {
      final json = {
        'id': 3,
        'subtotal': 50000,
        'delivery_fee': 12000,
        'commission_fee': 2500,
        'total_amount': 62000,
        'savings_amount': 38000,
        'payment_method': 'wallet',
        'payment_status': 'paid',
        'order_status': 'completed',
      };

      final order = Order.fromJson(json);
      expect(order.subtotal, '50000');
      expect(order.deliveryFee, '12000');
      expect(order.totalAmount, '62000');
    });
  });

  group('Order business logic getters', () {
    Order makeOrder(String status, {Map<String, dynamic>? review}) {
      return Order(
        id: 1,
        orderCode: 'SB-TEST',
        subtotal: '0',
        deliveryFee: '0',
        commissionFee: '0',
        totalAmount: '0',
        savingsAmount: '0',
        paymentMethod: 'wallet',
        paymentStatus: 'paid',
        orderStatus: status,
        review: review,
      );
    }

    test('canCancel is true only for confirmed orders', () {
      expect(makeOrder('confirmed').canCancel, true);
      expect(makeOrder('pending').canCancel, false);
      expect(makeOrder('delivered').canCancel, false);
      expect(makeOrder('completed').canCancel, false);
      expect(makeOrder('cancelled').canCancel, false);
    });

    test('canComplete is true only for delivered orders', () {
      expect(makeOrder('delivered').canComplete, true);
      expect(makeOrder('confirmed').canComplete, false);
      expect(makeOrder('completed').canComplete, false);
      expect(makeOrder('pending').canComplete, false);
    });

    test('canReview is true for completed without review', () {
      expect(makeOrder('completed').canReview, true);
      expect(
        makeOrder('completed', review: {'rating': 5}).canReview,
        false,
      );
      expect(makeOrder('delivered').canReview, false);
    });

    test('canDispute is true only for delivered orders', () {
      expect(makeOrder('delivered').canDispute, true);
      expect(makeOrder('completed').canDispute, false);
      expect(makeOrder('confirmed').canDispute, false);
    });
  });

  group('OrderItem.fromJson', () {
    test('parses with food_name field (standard backend response)', () {
      final json = {
        'id': 1,
        'food_item_id': 101,
        'food_name': 'Roti Coklat',
        'quantity': 2,
        'rescue_price': '12500',
        'image': 'https://example.com/roti.jpg',
      };

      final item = OrderItem.fromJson(json);
      expect(item.id, 1);
      expect(item.foodItemId, 101);
      expect(item.name, 'Roti Coklat');
      expect(item.quantity, 2);
      expect(item.price, '12500');
      expect(item.image, 'https://example.com/roti.jpg');
    });

    test('falls back to name field when food_name is absent', () {
      final json = {
        'id': 2,
        'food_item_id': 102,
        'name': 'Nasi Goreng',
        'quantity': 1,
        'line_total': '8000',
      };

      final item = OrderItem.fromJson(json);
      expect(item.name, 'Nasi Goreng');
      expect(item.price, '8000');
    });

    test('handles minimal JSON with defaults', () {
      final json = <String, dynamic>{};

      final item = OrderItem.fromJson(json);
      expect(item.id, 0);
      expect(item.foodItemId, 0);
      expect(item.name, '');
      expect(item.quantity, 1);
      expect(item.price, '0');
    });
  });
}
