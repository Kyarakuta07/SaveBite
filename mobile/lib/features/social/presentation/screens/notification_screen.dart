import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/notification.dart';
import '../../providers/social_provider.dart';

/// Notification inbox with infinite scroll and read-all action.
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).loadNotifications();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(notificationsProvider);
    if (state.isLoading || !state.hasMore) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  Future<void> _readAll() async {
    await ref.read(notificationsProvider.notifier).readAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua notifikasi ditandai sudah dibaca'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final hasUnread = state.unreadCount > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Text('Notifikasi'),
            if (hasUnread) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: AppTextStyles.labelSm
                      .copyWith(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        titleTextStyle: AppTextStyles.headlineSm,
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _readAll,
              child: Text(
                'Baca semua',
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: Builder(
        builder: (innerCtx) {
          if (state.isLoading && state.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state.error != null && state.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.error!, style: AppTextStyles.bodyMd),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => ref
                        .read(notificationsProvider.notifier)
                        .loadNotifications(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          if (state.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 64, color: AppColors.outlineVariant),
                  const SizedBox(height: 16),
                  Text('Tidak ada notifikasi',
                      style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref
                .read(notificationsProvider.notifier)
                .loadNotifications(),
            child: ListView.builder(
              controller: _scrollCtrl,
              itemCount:
                  state.notifications.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == state.notifications.length) {
                  // Load-more indicator
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                  );
                }
                return _NotificationTile(
                    notif: state.notifications[i]);
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Notification Tile ─────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notif});
  final AppNotification notif;

  static const _typeIcons = {
    'order': Icons.shopping_bag_outlined,
    'dispute': Icons.gavel_outlined,
    'wallet': Icons.account_balance_wallet_outlined,
    'flash_sale': Icons.flash_on_outlined,
    'promo': Icons.local_offer_outlined,
  };

  static const _typeColors = {
    'order': AppColors.primary,
    'dispute': AppColors.error,
    'wallet': AppColors.secondary,
    'flash_sale': AppColors.warning,
    'promo': AppColors.tertiary,
  };

  String _typeKey() {
    final raw = notif.type?.toLowerCase() ?? '';
    for (final key in _typeIcons.keys) {
      if (raw.contains(key)) return key;
    }
    return 'order';
  }

  /// Resolve a deep-link route from the notification's type and data payload.
  ///
  /// WHY here and not a shared utility: This mirrors the FCM push-tap routing
  /// in `_SplashScreenState._initNotifications`. The two should stay in sync —
  /// when a new notification type is added to the backend, both this method and
  /// the FCM handler need to be updated. A shared helper would be overkill until
  /// there are 3+ consumers.
  void _onTap(BuildContext context) {
    final type = notif.type?.toLowerCase() ?? '';
    final data = notif.data;
    final id = data?['id']?.toString() ??
        data?['order_id']?.toString() ??
        data?['food_item_id']?.toString() ??
        data?['merchant_id']?.toString();

    if (id == null || id.isEmpty) {
      // No linked resource — nothing to navigate to.
      return;
    }

    if (type.contains('order') || type.contains('dispute')) {
      context.push('/orders/$id');
    } else if (type.contains('food_item') || type.contains('flash_sale')) {
      context.push('/food-items/$id');
    } else if (type.contains('merchant')) {
      context.push('/merchants/$id');
    } else if (type.contains('wallet')) {
      context.push('/wallet');
    } else {
      // Unknown type — best-effort: try order detail since it's the most
      // common notification target.
      context.push('/orders/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = _typeKey();
    final icon = _typeIcons[key] ?? Icons.notifications_outlined;
    final color = _typeColors[key] ?? AppColors.primary;
    final isRead = notif.isRead;

    return InkWell(
      onTap: () => _onTap(context),
      child: Container(
        color: isRead
            ? Colors.transparent
            : AppColors.primary.withValues(alpha: 0.04),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon bubble
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notif.title != null)
                          Text(
                            notif.title!,
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                            ),
                          ),
                        if (notif.message != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            notif.message!,
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          notif.createdAt != null
                              ? Formatters.relativeTime(notif.createdAt!)
                              : '',
                          style: AppTextStyles.labelSm
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Unread dot
                  if (!isRead)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
          ],
        ),
      ),
    );
  }
}
