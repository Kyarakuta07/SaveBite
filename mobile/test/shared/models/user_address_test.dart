import 'package:flutter_test/flutter_test.dart';
import 'package:savebite/shared/models/user_address.dart';

void main() {
  group('UserAddress.fromJson', () {
    test('parses complete address JSON', () {
      final json = {
        'id': 1,
        'label': 'Rumah',
        'recipient_name': 'John Doe',
        'phone': '081234567890',
        'address': 'Jl. Test No. 1, Jakarta',
        'detail': 'Blok A No 5',
        'latitude': -6.2,
        'longitude': 106.8,
        'is_default': true,
        'created_at': '2026-05-08T10:00:00.000Z',
      };
      final addr = UserAddress.fromJson(json);
      expect(addr.id, 1);
      expect(addr.label, 'Rumah');
      expect(addr.recipientName, 'John Doe');
      expect(addr.phone, '081234567890');
      expect(addr.isDefault, true);
      expect(addr.latitude, -6.2);
      expect(addr.longitude, 106.8);
    });

    test('handles minimal JSON', () {
      final addr = UserAddress.fromJson({'id': 2});
      expect(addr.label, '');
      expect(addr.recipientName, '');
      expect(addr.phone, '');
      expect(addr.address, '');
      expect(addr.isDefault, false);
      expect(addr.latitude, isNull);
    });
  });

  group('UserAddress.toJson', () {
    test('serializes correctly', () {
      const addr = UserAddress(
        id: 1,
        label: 'Kantor',
        recipientName: 'Jane',
        phone: '08111',
        address: 'Jl. A',
        detail: 'Lt 2',
        latitude: -6.1,
        longitude: 106.7,
        isDefault: true,
      );
      final json = addr.toJson();
      expect(json['label'], 'Kantor');
      expect(json['recipient_name'], 'Jane');
      expect(json['is_default'], true);
      expect(json['latitude'], -6.1);
      expect(json['detail'], 'Lt 2');
    });

    test('omits null optional fields', () {
      const addr = UserAddress(
        id: 1,
        label: 'X',
        recipientName: 'Y',
        phone: '0',
        address: 'Z',
      );
      final json = addr.toJson();
      expect(json.containsKey('detail'), false);
      expect(json.containsKey('latitude'), false);
      expect(json.containsKey('longitude'), false);
    });
  });
}
