import 'package:equatable/equatable.dart';

import '../../core/utils/safe_parse.dart';

/// Wallet transaction entity matching backend API response.
class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.referenceType,
    this.referenceId,
    this.createdAt,
  });

  final int id;
  final String type; // topup | payment | refund | commission | withdrawal | income
  final String amount;
  final String balanceAfter;
  final String? description;
  final String? referenceType;
  final int? referenceId;
  final DateTime? createdAt;

  bool get isCredit =>
      type == 'topup' || type == 'refund' || type == 'income';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: toInt(json['id']),
        type: json['type'] as String? ?? '',
        amount: (json['amount'] ?? '0').toString(),
        balanceAfter: (json['balance_after'] ?? '0').toString(),
        description: json['description'] as String?,
        referenceType: json['reference_type'] as String?,
        referenceId: toIntOrNull(json['reference_id']),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  @override
  List<Object?> get props => [id, type, amount];
}
