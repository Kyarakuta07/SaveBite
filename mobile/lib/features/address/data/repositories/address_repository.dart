import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/user_address.dart';
import '../../../../shared/services/api_service.dart';

/// Address data source provider.
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.read(apiServiceProvider));
});

/// Repository for user saved address CRUD.
class AddressRepository {
  AddressRepository(this._dio);
  final Dio _dio;

  /// GET /me/addresses — list all saved addresses.
  Future<ApiResult<List<UserAddress>>> getAddresses() async {
    return ApiResult.guard(() async {
      final response = await _dio.get(ApiEndpoints.addresses);
      return (response.data['data'] as List)
          .map((e) => UserAddress.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// POST /me/addresses — create new address.
  Future<ApiResult<UserAddress>> createAddress({
    required String label,
    required String recipientName,
    required String phone,
    required String address,
    String? detail,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    return ApiResult.guard(() async {
      final response = await _dio.post(ApiEndpoints.addresses, data: {
        'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'address': address,
        if (detail != null && detail.isNotEmpty) 'detail': detail,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'is_default': isDefault,
      });
      return UserAddress.fromJson(response.data['data']);
    });
  }

  /// PUT /me/addresses/:id — update address.
  Future<ApiResult<UserAddress>> updateAddress({
    required int id,
    required String label,
    required String recipientName,
    required String phone,
    required String address,
    String? detail,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    return ApiResult.guard(() async {
      final response = await _dio.put(ApiEndpoints.address(id), data: {
        'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'address': address,
        if (detail != null && detail.isNotEmpty) 'detail': detail,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'is_default': isDefault,
      });
      return UserAddress.fromJson(response.data['data']);
    });
  }

  /// PATCH /me/addresses/:id/default — set as default.
  Future<ApiResult<void>> setDefaultAddress(int id) async {
    return ApiResult.guard(() async {
      await _dio.patch(ApiEndpoints.setDefaultAddress(id));
    });
  }

  /// DELETE /me/addresses/:id — delete address.
  Future<ApiResult<void>> deleteAddress(int id) async {
    return ApiResult.guard(() async {
      await _dio.delete(ApiEndpoints.address(id));
    });
  }
}
