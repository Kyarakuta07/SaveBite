import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savebite/core/errors/failures.dart';
import 'package:savebite/shared/models/notification.dart';
import 'package:savebite/features/social/data/repositories/social_repository.dart';
import 'package:savebite/features/social/providers/social_provider.dart';

// ─── Fake Repository ──────────────────────────

class FakeSocialRepository extends SocialRepository {
  FakeSocialRepository() : super(Dio());

  bool shouldFail = false;
  String failMessage = 'Test error';
  int totalPages = 2;

  final List<Map<String, dynamic>> _follows = [
    {'merchant_id': 10, 'display_name': 'Toko A'},
    {'merchant_id': 20, 'display_name': 'Toko B'},
  ];

  List<AppNotification> _makeNotifs(int page) => List.generate(
        3,
        (i) => AppNotification(
          id: '${(page - 1) * 3 + i + 1}',
          type: 'order_update',
          title: 'Notif ${(page - 1) * 3 + i + 1}',
          message: 'Message ${(page - 1) * 3 + i + 1}',
          readAt: i == 0 ? DateTime(2026, 5, 8) : null,
        ),
      );

  @override
  Future<ApiResult<List<Map<String, dynamic>>>> getFollows() async {
    if (shouldFail) return Failure(message: failMessage);
    return Success(List.of(_follows));
  }

  @override
  Future<ApiResult<void>> followMerchant(int merchantId) async {
    _follows.add({'merchant_id': merchantId, 'display_name': 'New'});
    return const Success(null);
  }

  @override
  Future<ApiResult<void>> unfollowMerchant(int merchantId) async {
    _follows.removeWhere((f) => f['merchant_id'] == merchantId);
    return const Success(null);
  }

  @override
  Future<ApiResult<({List<AppNotification> notifications, Map<String, dynamic> meta})>>
      getNotifications({int page = 1}) async {
    if (shouldFail) return Failure(message: failMessage);
    return Success((
      notifications: _makeNotifs(page),
      meta: {'current_page': page, 'last_page': totalPages},
    ));
  }

  @override
  Future<ApiResult<void>> readAllNotifications() async {
    return const Success(null);
  }
}

// ─── Follows Tests ────────────────────────────

void main() {
  group('FollowsNotifier', () {
    late FakeSocialRepository fakeRepo;
    late FollowsNotifier notifier;

    setUp(() {
      fakeRepo = FakeSocialRepository();
      notifier = FollowsNotifier(fakeRepo);
    });

    test('loadFollows populates follows list', () async {
      await notifier.loadFollows();
      expect(notifier.state.follows, hasLength(2));
      expect(notifier.state.isLoading, false);
    });

    test('follow adds merchant and refreshes', () async {
      await notifier.loadFollows();
      await notifier.follow(30);
      expect(notifier.state.follows, hasLength(3));
    });

    test('unfollow removes merchant and refreshes', () async {
      await notifier.loadFollows();
      await notifier.unfollow(10);
      expect(notifier.state.follows, hasLength(1));
    });

    test('sets error on failure', () async {
      fakeRepo.shouldFail = true;
      await notifier.loadFollows();
      expect(notifier.state.error, 'Test error');
    });
  });

  // ─── Notifications Tests ────────────────────

  group('NotificationsNotifier', () {
    late FakeSocialRepository fakeRepo;
    late NotificationsNotifier notifier;

    setUp(() {
      fakeRepo = FakeSocialRepository();
      notifier = NotificationsNotifier(fakeRepo);
    });

    test('loadNotifications populates list', () async {
      await notifier.loadNotifications();
      expect(notifier.state.notifications, hasLength(3));
      expect(notifier.state.currentPage, 1);
      expect(notifier.state.hasMore, true);
    });

    test('counts unread notifications', () async {
      await notifier.loadNotifications();
      // Per _makeNotifs: index 0 has readAt, indices 1 & 2 are unread
      expect(notifier.state.unreadCount, 2);
    });

    test('loadMore appends next page', () async {
      await notifier.loadNotifications();
      await notifier.loadMore();
      expect(notifier.state.notifications, hasLength(6));
      expect(notifier.state.hasMore, false);
    });

    test('loadMore does nothing when no more pages', () async {
      fakeRepo.totalPages = 1;
      await notifier.loadNotifications();
      await notifier.loadMore();
      expect(notifier.state.notifications, hasLength(3));
    });

    // ── Test 9.9: concurrent loading guard ──────────────
    // WHY: Without this guard, rapidly scrolling the NotificationScreen
    // fires multiple loadMore() calls simultaneously, which causes
    // duplicate notifications in the UI and incorrect page tracking.
    // The guard `if (state.isLoading || !state.hasMore) return` must be
    // verified explicitly.
    test('loadMore skips when isLoading is true (concurrent guard)', () async {
      await notifier.loadNotifications();
      expect(notifier.state.notifications, hasLength(3));

      // Fire two concurrent loadMore calls — only one should execute.
      final future1 = notifier.loadMore();
      final future2 = notifier.loadMore(); // should be a no-op (isLoading=true)
      await Future.wait([future1, future2]);

      // Should have exactly 6 items (page 1 + page 2), NOT 9 (page 1 + 2 + 2).
      expect(notifier.state.notifications, hasLength(6));
      expect(notifier.state.currentPage, 2);
    });

    test('readAll sets unreadCount to 0', () async {
      await notifier.loadNotifications();
      expect(notifier.state.unreadCount, 2);
      await notifier.readAll();
      expect(notifier.state.unreadCount, 0);
    });

    test('sets error on failure', () async {
      fakeRepo.shouldFail = true;
      await notifier.loadNotifications();
      expect(notifier.state.error, 'Test error');
    });
  });
}
