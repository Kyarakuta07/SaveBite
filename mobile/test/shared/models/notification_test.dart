import 'package:flutter_test/flutter_test.dart';
import 'package:savebite/shared/models/notification.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('parses notification with direct title/message', () {
      final json = {
        'id': 'abc-123',
        'type': 'order_update',
        'title': 'Pesanan Dikonfirmasi',
        'message': 'Pesanan SB-001 telah dikonfirmasi oleh mitra',
        'data': {'order_id': 101},
        'read_at': null,
        'created_at': '2026-05-08T10:00:00.000Z',
      };

      final notif = AppNotification.fromJson(json);
      expect(notif.id, 'abc-123');
      expect(notif.type, 'order_update');
      expect(notif.title, 'Pesanan Dikonfirmasi');
      expect(notif.message, 'Pesanan SB-001 telah dikonfirmasi oleh mitra');
      expect(notif.isRead, false);
      expect(notif.createdAt, isNotNull);
    });

    test('extracts title from data when top-level is null', () {
      final json = {
        'id': 'def-456',
        'type': 'promo',
        'title': null,
        'message': null,
        'data': {'title': 'Flash Sale!', 'message': 'Diskon 70%'},
        'read_at': '2026-05-08T11:00:00.000Z',
      };

      final notif = AppNotification.fromJson(json);
      expect(notif.title, 'Flash Sale!');
      expect(notif.message, 'Diskon 70%');
      expect(notif.isRead, true);
    });

    test('handles numeric id', () {
      final notif = AppNotification.fromJson({'id': 789, 'type': 'test'});
      expect(notif.id, '789');
    });

    test('isRead reflects read_at presence', () {
      final unread = AppNotification.fromJson({'id': '1', 'read_at': null});
      final read = AppNotification.fromJson({'id': '2', 'read_at': '2026-05-08T12:00:00.000Z'});
      expect(unread.isRead, false);
      expect(read.isRead, true);
    });
  });
}
