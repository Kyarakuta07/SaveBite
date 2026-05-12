import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../shared/models/notification.dart';
import '../data/repositories/social_repository.dart';

// ─── Follows State ───────────────────────────

class FollowsState {
  const FollowsState({
    this.follows = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Map<String, dynamic>> follows;
  final bool isLoading;
  final String? error;

  FollowsState copyWith({
    List<Map<String, dynamic>>? follows,
    bool? isLoading,
    String? error,
  }) =>
      FollowsState(
        follows: follows ?? this.follows,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final followsProvider =
    StateNotifierProvider<FollowsNotifier, FollowsState>((ref) {
  return FollowsNotifier(ref.read(socialRepositoryProvider));
});

class FollowsNotifier extends StateNotifier<FollowsState> {
  FollowsNotifier(this._repo) : super(const FollowsState());

  final SocialRepository _repo;

  Future<void> loadFollows() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.getFollows();
    switch (result) {
      case Success(:final data):
        state = state.copyWith(follows: data, isLoading: false);
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
    }
  }

  /// Follow and refresh list.
  Future<void> follow(int merchantId) async {
    await _repo.followMerchant(merchantId);
    await loadFollows();
  }

  /// Unfollow and refresh list.
  Future<void> unfollow(int merchantId) async {
    await _repo.unfollowMerchant(merchantId);
    await loadFollows();
  }
}

// ─── Notifications State ─────────────────────

class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.unreadCount = 0,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final int unreadCount;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
    int? unreadCount,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        hasMore: hasMore ?? this.hasMore,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref.read(socialRepositoryProvider));
});

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._repo) : super(const NotificationsState());

  final SocialRepository _repo;

  /// Load first page.
  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.getNotifications(page: 1);
    switch (result) {
      case Success(:final data):
        final currentPage = data.meta['current_page'] as int? ?? 1;
        final lastPage = data.meta['last_page'] as int? ?? 1;
        final unread =
            data.notifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          notifications: data.notifications,
          isLoading: false,
          currentPage: currentPage,
          hasMore: currentPage < lastPage,
          unreadCount: unread,
        );
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
    }
  }

  /// Load next page.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final nextPage = state.currentPage + 1;

    final result = await _repo.getNotifications(page: nextPage);
    switch (result) {
      case Success(:final data):
        final currentPage = data.meta['current_page'] as int? ?? nextPage;
        final lastPage = data.meta['last_page'] as int? ?? 1;
        state = state.copyWith(
          notifications: [
            ...state.notifications,
            ...data.notifications,
          ],
          isLoading: false,
          currentPage: currentPage,
          hasMore: currentPage < lastPage,
        );
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
    }
  }

  /// Mark all as read.
  Future<void> readAll() async {
    await _repo.readAllNotifications();
    state = state.copyWith(unreadCount: 0);
  }
}
