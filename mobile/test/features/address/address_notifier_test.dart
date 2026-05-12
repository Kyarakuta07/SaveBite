import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savebite/core/errors/failures.dart';
import 'package:savebite/shared/models/user_address.dart';
import 'package:savebite/features/address/data/repositories/address_repository.dart';
import 'package:savebite/features/address/providers/address_provider.dart';

// ─── Fake Repository ──────────────────────────

class FakeAddressRepository extends AddressRepository {
  FakeAddressRepository() : super(Dio());

  bool shouldFail = false;
  String failMessage = 'Test error';

  final List<UserAddress> _addresses = [
    const UserAddress(
      id: 1,
      label: 'Rumah',
      recipientName: 'User A',
      phone: '081234567890',
      address: 'Jl. Test No. 1',
      isDefault: true,
    ),
    const UserAddress(
      id: 2,
      label: 'Kantor',
      recipientName: 'User A',
      phone: '081234567891',
      address: 'Jl. Kantor No. 2',
      isDefault: false,
    ),
  ];

  @override
  Future<ApiResult<List<UserAddress>>> getAddresses() async {
    if (shouldFail) return Failure(message: failMessage);
    return Success(List.of(_addresses));
  }

  @override
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
    if (shouldFail) return Failure(message: failMessage);
    final newAddr = UserAddress(
      id: _addresses.length + 1,
      label: label,
      recipientName: recipientName,
      phone: phone,
      address: address,
      isDefault: isDefault,
    );
    _addresses.add(newAddr);
    return Success(newAddr);
  }

  @override
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
    if (shouldFail) return Failure(message: failMessage);
    return Success(UserAddress(
      id: id,
      label: label,
      recipientName: recipientName,
      phone: phone,
      address: address,
      isDefault: isDefault,
    ));
  }

  @override
  Future<ApiResult<void>> setDefaultAddress(int id) async {
    // Simulate backend behavior: reset all → set target.
    // See UserAddressController.php lines 103-106.
    for (int i = 0; i < _addresses.length; i++) {
      _addresses[i] = UserAddress(
        id: _addresses[i].id,
        label: _addresses[i].label,
        recipientName: _addresses[i].recipientName,
        phone: _addresses[i].phone,
        address: _addresses[i].address,
        isDefault: _addresses[i].id == id,
      );
    }
    return const Success(null);
  }

  @override
  Future<ApiResult<void>> deleteAddress(int id) async {
    _addresses.removeWhere((a) => a.id == id);
    return const Success(null);
  }
}

// ─── Tests ────────────────────────────────────

void main() {
  late FakeAddressRepository fakeRepo;
  late AddressNotifier notifier;

  setUp(() {
    fakeRepo = FakeAddressRepository();
    notifier = AddressNotifier(fakeRepo);
  });

  group('AddressNotifier.loadAddresses', () {
    test('loads addresses successfully', () async {
      await notifier.loadAddresses();
      expect(notifier.state.addresses, hasLength(2));
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('sets error on failure', () async {
      fakeRepo.shouldFail = true;
      fakeRepo.failMessage = 'Gagal memuat alamat';
      await notifier.loadAddresses();
      expect(notifier.state.addresses, isEmpty);
      expect(notifier.state.error, 'Gagal memuat alamat');
    });
  });

  group('AddressState.defaultAddress', () {
    test('returns the default address', () async {
      await notifier.loadAddresses();
      final def = notifier.state.defaultAddress;
      expect(def, isNotNull);
      expect(def!.label, 'Rumah');
      expect(def.isDefault, true);
    });

    test('returns null when no default', () {
      // Empty state
      expect(notifier.state.defaultAddress, isNull);
    });
  });

  group('AddressNotifier.createAddress', () {
    test('returns true on success and refreshes list', () async {
      await notifier.loadAddresses();
      final result = await notifier.createAddress(
        label: 'Kos',
        recipientName: 'User B',
        phone: '08222',
        address: 'Jl. Kos No. 3',
      );
      expect(result, true);
      expect(notifier.state.addresses, hasLength(3));
    });

    test('returns false on failure', () async {
      fakeRepo.shouldFail = true;
      final result = await notifier.createAddress(
        label: 'X',
        recipientName: 'Y',
        phone: '0',
        address: 'Z',
      );
      expect(result, false);
    });
  });

  group('AddressNotifier.updateAddress', () {
    test('returns true on success', () async {
      await notifier.loadAddresses();
      final result = await notifier.updateAddress(
        id: 1,
        label: 'Rumah Baru',
        recipientName: 'User A',
        phone: '08111',
        address: 'Jl. Baru No. 99',
      );
      expect(result, true);
    });
  });

  group('AddressNotifier.deleteAddress', () {
    test('removes address and refreshes', () async {
      await notifier.loadAddresses();
      expect(notifier.state.addresses, hasLength(2));
      await notifier.deleteAddress(1);
      expect(notifier.state.addresses, hasLength(1));
    });
  });

  // ── Test 9.5: setDefault ──────────────────────
  // WHY: Backend (UserAddressController.php:103-106) resets ALL addresses
  // to is_default=false then sets target to true inside a DB transaction.
  // The Flutter notifier must call the API and refresh the list so the UI
  // shows exactly one default badge. A bug here means checkout could ship
  // to the wrong address.
  group('AddressNotifier.setDefault', () {
    test('sets exactly one address as default after setDefault()', () async {
      await notifier.loadAddresses();

      // Initially: id=1 is default, id=2 is not.
      expect(
        notifier.state.addresses.where((a) => a.isDefault).length,
        1,
      );
      expect(notifier.state.defaultAddress!.id, 1);

      // Switch default to id=2.
      await notifier.setDefault(2);

      // After: only id=2 should be default.
      final defaults =
          notifier.state.addresses.where((a) => a.isDefault).toList();
      expect(defaults, hasLength(1));
      expect(defaults.first.id, 2);
      expect(defaults.first.label, 'Kantor');

      // Verify the previous default is no longer default.
      final oldDefault =
          notifier.state.addresses.firstWhere((a) => a.id == 1);
      expect(oldDefault.isDefault, false);
    });
  });
}
