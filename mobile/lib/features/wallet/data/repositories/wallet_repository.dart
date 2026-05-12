import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/wallet_transaction.dart';
import '../../../../shared/services/api_service.dart';

/// Wallet data source provider.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.read(apiServiceProvider));
});

/// Repository for user wallet operations.
class WalletRepository {
  WalletRepository(this._dio);
  final Dio _dio;

  /// GET /me/wallet — balance + summary.
  Future<ApiResult<Map<String, dynamic>>> getWallet() async {
    return ApiResult.guard(() async {
      final response = await _dio.get(ApiEndpoints.wallet);
      return response.data['data'] as Map<String, dynamic>;
    });
  }

  /// POST /me/wallet/topup — request top-up.
  Future<ApiResult<Map<String, dynamic>>> topUp({
    required int amount,
    required String paymentMethod,
  }) async {
    return ApiResult.guard(() async {
      final response = await _dio.post(ApiEndpoints.walletTopup, data: {
        'amount': amount,
        'payment_method': paymentMethod,
      });
      return response.data['data'] as Map<String, dynamic>;
    });
  }

  /// GET /me/wallet/transactions — transaction history.
  Future<ApiResult<({List<WalletTransaction> transactions, Map<String, dynamic> meta})>>
      getTransactions({int page = 1}) async {
    return ApiResult.guard(() async {
      final response = await _dio.get(
        ApiEndpoints.walletTransactions,
        queryParameters: {'page': page},
      );
      final data = response.data;
      final txns = (data['data'] as List)
          .map((e) =>
              WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = data['meta'] as Map<String, dynamic>? ?? {};
      return (transactions: txns, meta: meta);
    });
  }
}
