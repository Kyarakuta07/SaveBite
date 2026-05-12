import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savebite/core/errors/failures.dart';
import 'package:savebite/shared/models/wallet_transaction.dart';
import 'package:savebite/features/wallet/data/repositories/wallet_repository.dart';
import 'package:savebite/features/wallet/providers/wallet_provider.dart';

// ─── Fake Repository ──────────────────────────

class FakeWalletRepository extends WalletRepository {
  FakeWalletRepository() : super(Dio());

  bool shouldFailBalance = false;
  bool shouldFailTxns = false;
  String failMessage = 'Test error';
  int totalPages = 2;

  @override
  Future<ApiResult<Map<String, dynamic>>> getWallet() async {
    if (shouldFailBalance) return Failure(message: failMessage);
    return const Success({
      'balance': '150000',
      'total_top_up': '200000',
      'total_spent': '50000',
    });
  }

  @override
  Future<ApiResult<({List<WalletTransaction> transactions, Map<String, dynamic> meta})>>
      getTransactions({int page = 1}) async {
    if (shouldFailTxns) return Failure(message: failMessage);
    final txns = List.generate(
      3,
      (i) => WalletTransaction(
        id: (page - 1) * 3 + i + 1,
        type: i.isEven ? 'topup' : 'payment',
        amount: '${(i + 1) * 10000}',
        balanceAfter: '${150000 - (i + 1) * 10000}',
      ),
    );
    return Success((
      transactions: txns,
      meta: {'current_page': page, 'last_page': totalPages},
    ));
  }
}

// ─── Tests ────────────────────────────────────

void main() {
  late FakeWalletRepository fakeRepo;
  late WalletNotifier notifier;

  setUp(() {
    fakeRepo = FakeWalletRepository();
    notifier = WalletNotifier(fakeRepo);
  });

  group('WalletNotifier.loadWallet', () {
    test('loads balance and first page of transactions', () async {
      await notifier.loadWallet();
      expect(notifier.state.balance, '150000');
      expect(notifier.state.totalTopup, '200000');
      expect(notifier.state.totalSpent, '50000');
      expect(notifier.state.transactions, hasLength(3));
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('sets error when balance fetch fails', () async {
      fakeRepo.shouldFailBalance = true;
      await notifier.loadWallet();
      expect(notifier.state.error, 'Test error');
      // Should return early before fetching transactions
      expect(notifier.state.transactions, isEmpty);
    });

    test('sets error when transaction fetch fails', () async {
      fakeRepo.shouldFailTxns = true;
      await notifier.loadWallet();
      // Balance is set before txn call
      expect(notifier.state.balance, '150000');
      expect(notifier.state.error, 'Test error');
    });
  });

  group('WalletNotifier.loadMoreTransactions', () {
    test('appends page 2 transactions', () async {
      await notifier.loadWallet();
      await notifier.loadMoreTransactions();
      expect(notifier.state.transactions, hasLength(6));
      expect(notifier.state.hasMore, false);
    });

    test('does nothing when no more pages', () async {
      fakeRepo.totalPages = 1;
      await notifier.loadWallet();
      await notifier.loadMoreTransactions();
      expect(notifier.state.transactions, hasLength(3));
    });
  });

  group('WalletState.copyWith', () {
    test('preserves unchanged fields', () {
      const state = WalletState(balance: '100', totalTopup: '200');
      final updated = state.copyWith(isLoading: true);
      expect(updated.balance, '100');
      expect(updated.totalTopup, '200');
      expect(updated.isLoading, true);
    });
  });
}
