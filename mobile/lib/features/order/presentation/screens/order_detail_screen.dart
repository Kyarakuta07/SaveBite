import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../core/utils/image_url_helper.dart';
import '../../providers/order_provider.dart';

import '../widgets/order_action_bar.dart';

/// Full-screen order detail — the hub for delivery tracking,
/// review, dispute, cancel and reorder actions.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrder = ref.watch(orderDetailProvider(orderId));

    return asyncOrder.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
      ),
      data: (order) => Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: OrderActionBar(order: order),
        body: _OrderDetailBody(order: order, orderId: orderId),
      ),
    );
  }
}

// ─── Main Body ──────────────────────────────────

class _OrderDetailBody extends ConsumerWidget {
  const _OrderDetailBody({required this.order, required this.orderId});
  final Order order;
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          title: Text(order.orderCode, style: AppTextStyles.labelLg),
          centerTitle: true,
        ),

        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList.list(
            children: [
              _StatusStepper(status: order.orderStatus),
              const SizedBox(height: AppSpacing.md),
              _MerchantCard(merchant: order.merchant),
              const SizedBox(height: AppSpacing.md),
              _ItemsList(items: order.items),
              const SizedBox(height: AppSpacing.md),
              _PricingBreakdown(order: order),
              const SizedBox(height: AppSpacing.md),
              _PaymentInfo(order: order),
              if (order.delivery != null) ...[
                const SizedBox(height: AppSpacing.md),
                _DeliveryTracking(delivery: order.delivery!),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (order.createdAt != null)
                Text(
                  'Dipesan ${Formatters.dateTime(order.createdAt!)}',
                  style: AppTextStyles.labelMd,
                  textAlign: TextAlign.center,
                ),
              // Bottom padding for action bar
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Status Stepper ─────────────────────────────

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.status});
  final String status;

  static const _steps = ['pending', 'confirmed', 'picked_up', 'delivered', 'completed'];

  int get _currentIndex {
    if (status == 'cancelled') return -1;
    return _steps.indexOf(status).clamp(0, _steps.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text('Pesanan Dibatalkan',
                style: AppTextStyles.labelLg.copyWith(color: AppColors.error)),
          ],
        ),
      );
    }

    final idx = _currentIndex;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIdx = i ~/ 2;
            final active = stepIdx < idx;
            return Expanded(
              child: Container(
                height: 2,
                color: active ? AppColors.primary : AppColors.outlineVariant,
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isActive = stepIdx <= idx;
          final isCurrent = stepIdx == idx;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isCurrent ? 28 : 20,
                height: isCurrent ? 28 : 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.primary : AppColors.surfaceContainerHigh,
                  border: isCurrent
                      ? Border.all(color: AppColors.primaryLight, width: 2)
                      : null,
                ),
                child: isActive
                    ? Icon(Icons.check, size: isCurrent ? 16 : 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                Strings.orderStatus[_steps[stepIdx]] ?? _steps[stepIdx],
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 8,
                  color: isActive ? AppColors.primary : AppColors.outline,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Merchant Card ──────────────────────────────

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({this.merchant});
  final Map<String, dynamic>? merchant;

  @override
  Widget build(BuildContext context) {
    if (merchant == null) return const SizedBox.shrink();
    final name = merchant!['display_name'] as String? ?? 'Merchant';
    final category = merchant!['category'] as String? ?? '';
    final logo = merchant!['logo'] as String?;
    final merchantId = merchant!['id'] as int?;

    return GestureDetector(
      onTap: merchantId != null
          ? () => context.push('/merchants/$merchantId')
          : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.15),
              backgroundImage: logo != null
                  ? NetworkImage(
                      ImageUrlHelper.resolve(logo) ?? logo,
                    )
                  : null,
              child: logo == null
                  ? const Icon(Icons.store, color: AppColors.primary, size: 22)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelLg),
                  if (category.isNotEmpty)
                    Text(category, style: AppTextStyles.labelMd),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

// ─── Items List ─────────────────────────────────

class _ItemsList extends StatelessWidget {
  const _ItemsList({required this.items});
  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Item Pesanan', style: AppTextStyles.labelLg),
          const SizedBox(height: AppSpacing.sm),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: item.image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          child: AppNetworkImage(
                            imageUrl: item.image,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.fastfood,
                            fallbackIconSize: 20,
                          ),
                        )
                      : const Icon(Icons.fastfood, color: AppColors.outline, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTextStyles.bodyMd,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('x${item.quantity}', style: AppTextStyles.labelMd),
                    ],
                  ),
                ),
                Text(Formatters.rupiah(item.price), style: AppTextStyles.labelLg),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── Pricing Breakdown ──────────────────────────

class _PricingBreakdown extends StatelessWidget {
  const _PricingBreakdown({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: [
          _PriceRow('Subtotal', order.subtotal),
          const SizedBox(height: AppSpacing.xs),
          _PriceRow('Ongkos Kirim', order.deliveryFee),
          const SizedBox(height: AppSpacing.xs),
          _PriceRow('Penghematan Anda', '-${order.savingsAmount}',
              valueColor: AppColors.success),
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Bayar', style: AppTextStyles.headlineSm.copyWith(fontSize: 16)),
              Text(Formatters.rupiah(order.totalAmount),
                  style: AppTextStyles.price.copyWith(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        Text(
          value.startsWith('-') ? Formatters.rupiah(value.substring(1)).replaceFirst('Rp', '-Rp') : Formatters.rupiah(value),
          style: AppTextStyles.bodyMd.copyWith(
            color: valueColor ?? AppColors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Payment Info ───────────────────────────────

class _PaymentInfo extends StatelessWidget {
  const _PaymentInfo({required this.order});
  final Order order;

  String _methodLabel(String method) => switch (method) {
    'wallet' => 'Wallet',
    'qris' => 'QRIS',
    'e_wallet' => 'E-Wallet',
    'bank_transfer' => 'Transfer Bank',
    _ => method,
  };

  String _statusLabel(String status) => switch (status) {
    'pending' => 'Menunggu',
    'paid' => 'Lunas',
    'failed' => 'Gagal',
    'refunded' => 'Dikembalikan',
    _ => status,
  };

  Color _statusColor(String status) => switch (status) {
    'paid' => AppColors.statusCompleted,
    'failed' => AppColors.error,
    'refunded' => AppColors.statusDelivered,
    _ => AppColors.statusPending,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.payment, color: AppColors.outline, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(_methodLabel(order.paymentMethod), style: AppTextStyles.bodyMd),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(order.paymentStatus).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              _statusLabel(order.paymentStatus),
              style: AppTextStyles.labelSm.copyWith(
                color: _statusColor(order.paymentStatus),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Delivery Tracking ──────────────────────────

class _DeliveryTracking extends StatelessWidget {
  const _DeliveryTracking({required this.delivery});
  final Map<String, dynamic> delivery;

  @override
  Widget build(BuildContext context) {
    final status = delivery['status'] as String? ?? 'searching';
    final driverName = delivery['driver_name'] as String?;
    final driverPhone = delivery['driver_phone'] as String?;
    final vehicle = delivery['driver_vehicle'] as String?;
    final trackingUrl = delivery['live_tracking_url'] as String?;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('Pengiriman', style: AppTextStyles.labelLg),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  Strings.deliveryStatus[status] ?? status,
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.tertiary),
                ),
              ),
            ],
          ),
          if (driverName != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  child: Icon(Icons.person, size: 20, color: AppColors.outline),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driverName, style: AppTextStyles.labelLg),
                      if (vehicle != null)
                        Text(vehicle, style: AppTextStyles.labelMd),
                    ],
                  ),
                ),
                if (driverPhone != null)
                  IconButton(
                    onPressed: () => launchUrl(Uri.parse('tel:$driverPhone')),
                    icon: const Icon(Icons.phone, color: AppColors.primary),
                    iconSize: 20,
                  ),
              ],
            ),
          ],
          if (trackingUrl != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(trackingUrl),
                    mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.map, size: 18),
                label: const Text('Lacak Pengiriman'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Error View ─────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.outline),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
