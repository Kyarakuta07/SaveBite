import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/order.dart';
import '../../data/repositories/order_repository.dart';
import '../../providers/order_provider.dart';

/// Conditional action bar shown at bottom of OrderDetailScreen.
///
/// Actions depend on order status:
/// - delivered  → "Konfirmasi Selesai" + "Ajukan Komplain"
/// - completed + canReview → "Beri Ulasan"
/// - confirmed → "Batalkan Pesanan"
/// - any completed/cancelled → "Pesan Lagi"
class OrderActionBar extends ConsumerWidget {
  const OrderActionBar({required this.order, super.key});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = <Widget>[];

    // Delivered → Complete + Dispute
    if (order.canComplete) {
      actions.add(Expanded(
        child: ElevatedButton(
          onPressed: () => _complete(context, ref),
          child: const Text('Konfirmasi Selesai'),
        ),
      ));
      actions.add(const SizedBox(width: AppSpacing.sm));
      actions.add(OutlinedButton(
        onPressed: () => context.push('/dispute/${order.id}'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
        ),
        child: const Text('Komplain'),
      ));
    }

    // Completed + no review yet → Review
    if (order.canReview) {
      actions.add(Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _showReviewSheet(context),
          icon: const Icon(Icons.star, size: 18),
          label: const Text('Beri Ulasan'),
        ),
      ));
    }

    // Confirmed → Cancel
    if (order.canCancel) {
      actions.add(Expanded(
        child: OutlinedButton(
          onPressed: () => _cancel(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          child: const Text('Batalkan Pesanan'),
        ),
      ));
    }

    // Completed or Cancelled → Reorder
    if (order.orderStatus == 'completed' || order.orderStatus == 'cancelled') {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: AppSpacing.sm));
      actions.add(OutlinedButton.icon(
        onPressed: () => _reorder(context, ref),
        icon: const Icon(Icons.replay, size: 18),
        label: const Text('Pesan Lagi'),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: actions),
      ),
    );
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Selesai'),
        content: const Text('Pesanan sudah diterima dengan baik?'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => ctx.pop(true), child: const Text('Ya, Selesai')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(orderRepositoryProvider).completeOrder(order.id);
    if (!context.mounted) return;
    switch (result) {
      case Success():
        ref.invalidate(orderDetailProvider(order.id));
        ref.read(orderListProvider.notifier).loadOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan selesai! Terima kasih 🎉')),
        );
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Refund akan dikembalikan ke wallet Anda.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Tidak')),
          ElevatedButton(
            onPressed: () => ctx.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(orderRepositoryProvider).cancelOrder(order.id);
    if (!context.mounted) return;
    switch (result) {
      case Success():
        ref.invalidate(orderDetailProvider(order.id));
        ref.read(orderListProvider.notifier).loadOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan dibatalkan. Refund dikembalikan.')),
        );
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _reorder(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(orderRepositoryProvider).reorder(order.id);
    if (!context.mounted) return;
    switch (result) {
      case Success(:final data):
        final items = data['available_items'] as List? ?? [];
        if (items.isNotEmpty) {
          final firstItemId = items.first['id'] as int? ?? items.first['food_item_id'] as int?;
          if (firstItemId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${items.length} item siap dipesan kembali')),
            );
            context.push('/food-items/$firstItemId');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item tidak tersedia saat ini')),
          );
        }
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => ReviewBottomSheet(orderId: order.id),
    );
  }
}

// ─── Review Bottom Sheet ────────────────────────

class ReviewBottomSheet extends ConsumerStatefulWidget {
  const ReviewBottomSheet({required this.orderId, super.key});
  final int orderId;

  @override
  ConsumerState<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends ConsumerState<ReviewBottomSheet> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final result = await ref.read(orderRepositoryProvider).createReview(
      orderId: widget.orderId,
      rating: _rating,
      comment: _commentCtrl.text.trim(),
      isAnonymous: _isAnonymous,
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.pop(context);
        ref.invalidate(orderDetailProvider(widget.orderId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ulasan berhasil dikirim ⭐')),
        );
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text('Beri Ulasan', style: AppTextStyles.headlineSm),
          const SizedBox(height: AppSpacing.md),

          // Star rating row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starNum = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starNum),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starNum <= _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: starNum <= _rating
                        ? AppColors.secondaryContainer
                        : AppColors.outlineVariant,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),

          // Comment
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Tulis komentar (opsional)...',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Anonymous toggle
          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v ?? false),
                activeColor: AppColors.primary,
              ),
              const Text('Kirim sebagai anonim'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Kirim Ulasan'),
            ),
          ),
        ],
      ),
    );
  }
}
