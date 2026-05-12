import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../shared/models/wallet_transaction.dart';
import '../data/repositories/wallet_repository.dart';

// ─── Wallet State ────────────────────────────

class WalletState {
  const WalletState({
    this.balance = '0',
    this.totalTopup = '0',
    this.totalSpent = '0',
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  final String balance;
  final String totalTopup;
  final String totalSpent;
  final List<WalletTransaction> transactions;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  WalletState copyWith({
    String? balance,
    String? totalTopup,
    String? totalSpent,
    List<WalletTransaction>? transactions,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) =>
      WalletState(
        balance: balance ?? this.balance,
        totalTopup: totalTopup ?? this.totalTopup,
        totalSpent: totalSpent ?? this.totalSpent,
        transactions: transactions ?? this.transactions,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        hasMore: hasMore ?? this.hasMore,
      );
}

// ─── Wallet Notifier ─────────────────────────

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref.read(walletRepositoryProvider));
});

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier(this._repo) : super(const WalletState());

  final WalletRepository _repo;

  /// Load wallet balance + first page of transactions.
  Future<void> loadWallet() async {
    state = state.copyWith(isLoading: true, error: null);

    // Fetch balance
    final balanceResult = await _repo.getWallet();
    switch (balanceResult) {
      case Success(:final data):
        state = state.copyWith(
          balance: (data['balance'] ?? '0').toString(),
          totalTopup: (data['total_top_up'] ?? '0').toString(),
          totalSpent: (data['total_spent'] ?? '0').toString(),
        );
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
        return;
    }

    // Fetch transactions
    final txnResult = await _repo.getTransactions(page: 1);
    switch (txnResult) {
      case Success(:final data):
        final currentPage = data.meta['current_page'] as int? ?? 1;
        final lastPage = data.meta['last_page'] as int? ?? 1;
        state = state.copyWith(
          transactions: data.transactions,
          isLoading: false,
          currentPage: currentPage,
          hasMore: currentPage < lastPage,
        );
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
    }
  }

  /// Load more transactions.
  Future<void> loadMoreTransactions() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final nextPage = state.currentPage + 1;

    final result = await _repo.getTransactions(page: nextPage);
    switch (result) {
      case Success(:final data):
        final currentPage = data.meta['current_page'] as int? ?? nextPage;
        final lastPage = data.meta['last_page'] as int? ?? 1;
        state = state.copyWith(
          transactions: [...state.transactions, ...data.transactions],
          isLoading: false,
          currentPage: currentPage,
          hasMore: currentPage < lastPage,
        );
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
    }
  }
}
