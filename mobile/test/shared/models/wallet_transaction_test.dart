import 'package:flutter_test/flutter_test.dart';
import 'package:savebite/shared/models/wallet_transaction.dart';

void main() {
  group('WalletTransaction.fromJson', () {
    test('parses complete transaction JSON', () {
      final json = {
        'id': 1,
        'type': 'topup',
        'amount': '100000',
        'balance_after': '100000',
        'description': 'Top up via QRIS',
        'reference_type': 'topup_request',
        'reference_id': 42,
        'created_at': '2026-05-08T10:00:00.000Z',
      };

      final txn = WalletTransaction.fromJson(json);
      expect(txn.id, 1);
      expect(txn.type, 'topup');
      expect(txn.amount, '100000');
      expect(txn.balanceAfter, '100000');
      expect(txn.description, 'Top up via QRIS');
      expect(txn.referenceType, 'topup_request');
      expect(txn.referenceId, 42);
      expect(txn.createdAt, isNotNull);
    });

    test('handles numeric amount (backend edge case)', () {
      final json = {
        'id': 2,
        'type': 'payment',
        'amount': 25000,
        'balance_after': 75000,
      };

      final txn = WalletTransaction.fromJson(json);
      expect(txn.amount, '25000');
      expect(txn.balanceAfter, '75000');
    });
  });

  group('WalletTransaction.isCredit', () {
    WalletTransaction makeTxn(String type) => WalletTransaction(
          id: 1,
          type: type,
          amount: '10000',
          balanceAfter: '10000',
        );

    test('topup is credit', () {
      expect(makeTxn('topup').isCredit, true);
    });

    test('refund is credit', () {
      expect(makeTxn('refund').isCredit, true);
    });

    test('income is credit', () {
      expect(makeTxn('income').isCredit, true);
    });

    test('payment is not credit', () {
      expect(makeTxn('payment').isCredit, false);
    });

    test('commission is not credit', () {
      expect(makeTxn('commission').isCredit, false);
    });

    test('withdrawal is not credit', () {
      expect(makeTxn('withdrawal').isCredit, false);
    });
  });
}
