import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../shared/models/user_address.dart';
import '../data/repositories/address_repository.dart';

// ─── Address State ───────────────────────────

class AddressState {
  const AddressState({
    this.addresses = const [],
    this.isLoading = false,
    this.error,
  });

  final List<UserAddress> addresses;
  final bool isLoading;
  final String? error;

  /// The default address, if any.
  UserAddress? get defaultAddress =>
      addresses.where((a) => a.isDefault).firstOrNull;

  AddressState copyWith({
    List<UserAddress>? addresses,
    bool? isLoading,
    String? error,
  }) =>
      AddressState(
        addresses: addresses ?? this.addresses,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Address Notifier ────────────────────────

final addressProvider =
    StateNotifierProvider<AddressNotifier, AddressState>((ref) {
  return AddressNotifier(ref.read(addressRepositoryProvider));
});

class AddressNotifier extends StateNotifier<AddressState> {
  AddressNotifier(this._repo) : super(const AddressState());

  final AddressRepository _repo;

  /// Load all addresses.
  Future<void> loadAddresses() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.getAddresses();
    switch (result) {
      case Success(:final data):
        state = state.copyWith(addresses: data, isLoading: false);
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
    }
  }

  /// Create a new address, then refresh the list.
  Future<bool> createAddress({
    required String label,
    required String recipientName,
    required String phone,
    required String address,
    String? detail,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final result = await _repo.createAddress(
      label: label,
      recipientName: recipientName,
      phone: phone,
      address: address,
      detail: detail,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );
    switch (result) {
      case Success():
        await loadAddresses();
        return true;
      case Failure():
        return false;
    }
  }

  /// Update existing address.
  Future<bool> updateAddress({
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
    final result = await _repo.updateAddress(
      id: id,
      label: label,
      recipientName: recipientName,
      phone: phone,
      address: address,
      detail: detail,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );
    switch (result) {
      case Success():
        await loadAddresses();
        return true;
      case Failure():
        return false;
    }
  }

  /// Set as default address.
  Future<void> setDefault(int id) async {
    await _repo.setDefaultAddress(id);
    await loadAddresses();
  }

  /// Delete an address.
  Future<void> deleteAddress(int id) async {
    await _repo.deleteAddress(id);
    await loadAddresses();
  }
}
