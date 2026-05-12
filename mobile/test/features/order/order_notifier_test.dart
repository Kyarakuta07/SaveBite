import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savebite/core/errors/failures.dart';
import 'package:savebite/shared/models/order.dart';
import 'package:savebite/features/order/data/repositories/order_repository.dart';
import 'package:savebite/features/order/providers/order_provider.dart';

// ─── Fake Repository ──────────────────────────

class FakeOrderRepository extends OrderRepository {
  FakeOrderRepository() : super(Dio());

  bool shouldFail = false;
  String failMessage = 'Test error';
  int totalPages = 2;

  Order _makeOrder(int id) => Order(
        id: id,
        orderCode: 'SB-TEST-${id.toString().padLeft(4, '0')}',
        subtotal: '25000',
        deliveryFee: '12000',
        commissionFee: '1250',
        totalAmount: '37000',
        savingsAmount: '13000',
        paymentMethod: 'wallet',
        paymentStatus: 'paid',
        orderStatus: 'completed',
      );

  @override
  Future<ApiResult<({List<Order> orders, Map<String, dynamic> meta})>>
      getOrders({int page = 1}) async {
    if (shouldFail) return Failure(message: failMessage);
    final orders = List.generate(3, (i) => _makeOrder((page - 1) * 3 + i + 1));
    return Success((
      orders: orders,
      meta: {'current_page': page, 'last_page': totalPages},
    ));
  }

  @override
  Future<ApiResult<Order>> getOrderDetail(int id) async {
    if (shouldFail) return Failure(message: failMessage);
    return Success(_makeOrder(id));
  }
}

// ─── Tests ────────────────────────────────────

void main() {
  late FakeOrderRepository fakeRepo;
  late OrderListNotifier notifier;

  setUp(() {
    fakeRepo = FakeOrderRepository();
    notifier = OrderListNotifier(fakeRepo);
  });

  group('OrderListNotifier.loadOrders', () {
    test('loads first page successfully', () async {
      await notifier.loadOrders();
      expect(notifier.state.orders, hasLength(3));
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.currentPage, 1);
      expect(notifier.state.hasMore, true);
    });

    test('sets error on failure', () async {
      fakeRepo.shouldFail = true;
      fakeRepo.failMessage = 'Server error';
      await notifier.loadOrders();
      expect(notifier.state.orders, isEmpty);
      expect(notifier.state.error, 'Server error');
    });
  });

  group('OrderListNotifier.loadMore', () {
    test('appends page 2 orders', () async {
      await notifier.loadOrders();
      await notifier.loadMore();
      expect(notifier.state.orders, hasLength(6));
      expect(notifier.state.currentPage, 2);
      expect(notifier.state.hasMore, false);
    });

    test('does nothing when no more pages', () async {
      fakeRepo.totalPages = 1;
      await notifier.loadOrders();
      await notifier.loadMore();
      expect(notifier.state.orders, hasLength(3));
    });

    test('preserves order codes across pages', () async {
      await notifier.loadOrders();
      await notifier.loadMore();
      expect(notifier.state.orders[0].orderCode, 'SB-TEST-0001');
      expect(notifier.state.orders[5].orderCode, 'SB-TEST-0006');
    });
  });

  group('OrderListState.copyWith', () {
    test('copies with partial updates', () {
      const state = OrderListState();
      final updated = state.copyWith(isLoading: true, currentPage: 3);
      expect(updated.isLoading, true);
      expect(updated.currentPage, 3);
      expect(updated.orders, isEmpty); // unchanged
    });

    test('error is cleared when set to null via copyWith', () {
      final state = const OrderListState().copyWith(error: 'oops');
      expect(state.error, 'oops');
      // copyWith with error: null clears it (because nullable param)
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });
  });
}
