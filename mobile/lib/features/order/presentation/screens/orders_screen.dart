import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../providers/order_provider.dart';

/// Orders tab — list of user's orders with status chips.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderListProvider.notifier).loadOrders();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(orderListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.marginMobile),
          child: CircleAvatar(
            backgroundColor: AppColors.surfaceVariant,
            child: Icon(Icons.person, size: 20, color: AppColors.outline),
          ),
        ),
        leadingWidth: 56,
        title: Text(
          'SaveBite',
          style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.primary,
            onPressed: () => context.push('/notifications'),
          ),
        ],
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(45),
          child: Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _OrdersTab(label: 'Sedang Berjalan', active: true),
                ),
                Expanded(child: _OrdersTab(label: 'Riwayat')),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(orderListProvider.notifier).loadOrders(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(OrderListState state) {
    if (state.isLoading && state.orders.isEmpty) {
      return _buildShimmerList();
    }
    if (state.error != null && state.orders.isEmpty) {
      return _buildError(state.error!);
    }
    if (state.orders.isEmpty) {
      return _buildEmpty();
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      itemCount: state.orders.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index < state.orders.length) {
          return _OrderCard(order: state.orders[index]);
        }
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return ShimmerPlaceholder.list(count: 4, itemHeight: 120);
  }

  Widget _buildError(String message) {
    return ErrorStateWidget(
      message: message,
      onRetry: () => ref.read(orderListProvider.notifier).loadOrders(),
    );
  }

  Widget _buildEmpty() {
    return EmptyStateWidget(
      icon: Icons.shopping_bag_outlined,
      title: 'Belum ada pesanan',
      subtitle: 'Mulai rescue makanan sekarang!',
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.label, this.active = false});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelLg.copyWith(
          color: active ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Order Card ──────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.statusPending;
      case 'confirmed':
        return AppColors.statusConfirmed;
      case 'picked_up':
      case 'delivered':
        return AppColors.statusDelivered;
      case 'completed':
        return AppColors.statusCompleted;
      case 'cancelled':
        return AppColors.statusCancelled;
      default:
        return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText =
        Strings.orderStatus[order.orderStatus] ?? order.orderStatus;
    final color = _statusColor(order.orderStatus);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () {
          context.push('/orders/${order.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: order code + status chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.orderCode, style: AppTextStyles.labelLg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: AppTextStyles.labelSm.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Items summary
              if (order.items.isNotEmpty)
                Text(
                  order.items.map((i) => '${i.name} x${i.quantity}').join(', '),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: AppSpacing.sm),

              // Footer: total + date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.rupiah(order.totalAmount),
                    style: AppTextStyles.headlineSm.copyWith(
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                  if (order.createdAt != null)
                    Text(
                      Formatters.relativeTime(order.createdAt!),
                      style: AppTextStyles.labelMd,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
