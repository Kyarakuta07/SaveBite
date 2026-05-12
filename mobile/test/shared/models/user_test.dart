import 'package:flutter_test/flutter_test.dart';
import 'package:savebite/shared/models/user.dart';

void main() {
  group('User.fromJson', () {
    test('parses complete user JSON correctly', () {
      final json = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@savebite.id',
        'phone': '081234567890',
        'avatar': 'https://example.com/avatar.jpg',
        'wallet_balance': '150000',
        'point_balance': 250,
        'total_saved': '75000',
        'total_rescued': 12,
        'total_orders': 15,
        'tier': 'Pemburu Diskon',
        'tier_detail': {'name': 'Pemburu Diskon', 'icon': '🎯', 'min_orders': 10},
        'fcm_token': 'fcm_abc123',
        'default_address': {
          'id': 1,
          'label': 'Rumah',
          'address': 'Jl. Test No. 1',
        },
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.name, 'Test User');
      expect(user.email, 'test@savebite.id');
      expect(user.phone, '081234567890');
      expect(user.avatar, 'https://example.com/avatar.jpg');
      expect(user.walletBalance, '150000');
      expect(user.pointBalance, 250);
      expect(user.totalSaved, '75000');
      expect(user.totalRescued, 12);
      expect(user.totalOrders, 15);
      expect(user.tier, 'Pemburu Diskon');
      expect(user.tierIcon, '🎯');
      expect(user.fcmToken, 'fcm_abc123');
      expect(user.defaultAddress, isNotNull);
    });

    test('parses tier as String correctly', () {
      final json = {
        'id': 2,
        'name': 'User A',
        'email': 'a@test.id',
        'tier': 'Eco Warrior',
      };

      final user = User.fromJson(json);
      expect(user.tier, 'Eco Warrior');
      expect(user.tierIcon, isNull);
    });

    test('parses legacy tier as Map correctly', () {
      final json = {
        'id': 3,
        'name': 'User B',
        'email': 'b@test.id',
        'tier': {'name': 'SaveBite Legend', 'icon': '👑'},
      };

      final user = User.fromJson(json);
      expect(user.tier, 'SaveBite Legend');
      expect(user.tierIcon, '👑');
    });

    test('extracts tierIcon from tier_detail when tier is String', () {
      final json = {
        'id': 4,
        'name': 'User C',
        'email': 'c@test.id',
        'tier': 'Mahasiswa Hemat',
        'tier_detail': {'name': 'Mahasiswa Hemat', 'icon': '🎓'},
      };

      final user = User.fromJson(json);
      expect(user.tier, 'Mahasiswa Hemat');
      expect(user.tierIcon, '🎓');
    });

    test('handles minimal JSON with defaults', () {
      final json = {
        'id': 5,
        'name': 'Minimal User',
        'email': 'minimal@test.id',
      };

      final user = User.fromJson(json);
      expect(user.id, 5);
      expect(user.walletBalance, '0');
      expect(user.pointBalance, 0);
      expect(user.totalSaved, '0');
      expect(user.totalRescued, 0);
      expect(user.totalOrders, 0);
      expect(user.tier, 'Mahasiswa Hemat');
      expect(user.phone, isNull);
      expect(user.avatar, isNull);
      expect(user.fcmToken, isNull);
      expect(user.defaultAddress, isNull);
    });

    test('handles wallet_balance as int (backend edge case)', () {
      final json = {
        'id': 6,
        'name': 'Int Balance',
        'email': 'int@test.id',
        'wallet_balance': 50000,
        'total_saved': 25000,
      };

      final user = User.fromJson(json);
      expect(user.walletBalance, '50000');
      expect(user.totalSaved, '25000');
    });
  });

  group('User.copyWith', () {
    test('copies with updated fields', () {
      const user = User(id: 1, name: 'Original', email: 'a@b.c');
      final updated = user.copyWith(name: 'Updated', tier: 'Eco Warrior');

      expect(updated.id, 1); // unchanged
      expect(updated.email, 'a@b.c'); // unchanged
      expect(updated.name, 'Updated');
      expect(updated.tier, 'Eco Warrior');
    });

    test('preserves all fields when no args passed', () {
      const user = User(
        id: 1,
        name: 'Test',
        email: 'x@y.z',
        walletBalance: '100',
        pointBalance: 50,
      );
      final copy = user.copyWith();
      expect(copy.name, user.name);
      expect(copy.walletBalance, user.walletBalance);
      expect(copy.pointBalance, user.pointBalance);
    });
  });

  group('User equality (Equatable)', () {
    test('equal users with same id, name, email', () {
      const user1 = User(id: 1, name: 'A', email: 'a@b.c');
      const user2 = User(id: 1, name: 'A', email: 'a@b.c', tier: 'X');

      // Equatable props: [id, name, email]
      expect(user1, equals(user2));
    });

    test('different users with different email', () {
      const user1 = User(id: 1, name: 'A', email: 'a@b.c');
      const user2 = User(id: 1, name: 'A', email: 'different@b.c');
      expect(user1, isNot(equals(user2)));
    });
  });
}
