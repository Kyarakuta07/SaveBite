import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../shared/models/order.dart';
import '../data/repositories/order_repository.dart';

// ─── Order List State ────────────────────────

class OrderListState {
  const OrderListState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasMore = true,
  });

  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  OrderListState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? lastPage,
    bool? hasMore,
  }) =>
      OrderListState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        lastPage: lastPage ?? this.lastPage,
        hasMore: hasMore ?? this.hasMore,
      );
}

// ─── Order List Notifier ─────────────────────

final orderListProvider =
    StateNotifierProvider<OrderListNotifier, OrderListState>((ref) {
  return OrderListNotifier(ref.read(orderRepositoryProvider));
});

class OrderListNotifier extends StateNotifier<OrderListState> {
  OrderListNotifier(this._repo) : super(const OrderListState());

  final OrderRepository _repo;

  /// Load first page.
  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.getOrders(page: 1);
    switch (result) {
      case Success(:final data):
        final currentPage = data.meta['current_page'] as int? ?? 1;
        final lastPage = data.meta['last_page'] as int? ?? 1;
        state = state.copyWith(
          orders: data.orders,
          isLoading: false,
          currentPage: currentPage,
          lastPage: lastPage,
          hasMore: currentPage < lastPage,
        );
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
    }
  }

  /// Load next page (infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final nextPage = state.currentPage + 1;

    final result = await _repo.getOrders(page: nextPage);
    switch (result) {
      case Success(:final data):
        final currentPage = data.meta['current_page'] as int? ?? nextPage;
        final lastPage = data.meta['last_page'] as int? ?? 1;
        state = state.copyWith(
          orders: [...state.orders, ...data.orders],
          isLoading: false,
          currentPage: currentPage,
          lastPage: lastPage,
          hasMore: currentPage < lastPage,
        );
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
    }
  }
}

// ─── Order Detail Provider ───────────────────

final orderDetailProvider =
    FutureProvider.family<Order, int>((ref, orderId) async {
  final repo = ref.read(orderRepositoryProvider);
  final result = await repo.getOrderDetail(orderId);
  switch (result) {
    case Success(:final data):
      return data;
    case Failure(:final message):
      throw Exception(message);
  }
});
