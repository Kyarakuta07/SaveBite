import 'dart:async';

// TODO: remove legacy detail widgets after the next visual QA pass.
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_labels.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/food_item.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/stitch_components.dart';
import '../../providers/browse_provider.dart';

/// Product detail screen — displays food item info, merchant, pricing,
/// flash sale countdown, and "Beli Sekarang" CTA.
///
/// Route: `/food-items/:id`
class FoodItemDetailScreen extends ConsumerStatefulWidget {
  const FoodItemDetailScreen({required this.itemId, super.key});
  final int itemId;

  @override
  ConsumerState<FoodItemDetailScreen> createState() =>
      _FoodItemDetailScreenState();
}

class _FoodItemDetailScreenState extends ConsumerState<FoodItemDetailScreen> {
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _secondsRemaining = seconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncItem = ref.watch(foodItemDetailProvider(widget.itemId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: asyncItem.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Gagal memuat detail', style: AppTextStyles.headlineSm),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  err.toString(),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(foodItemDetailProvider(widget.itemId)),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (item) {
          // Start flash sale countdown on first build
          if (item.isFlashSale &&
              item.secondsRemaining != null &&
              _countdownTimer == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startCountdown(item.secondsRemaining!);
            });
          }
          return _DetailBody(item: item, secondsRemaining: _secondsRemaining);
        },
      ),
    );
  }
}

// ─── Detail Body ─────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.item, required this.secondsRemaining});

  final FoodItem item;
  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    final heroHeight = MediaQuery.sizeOf(context).height < 740 ? 300.0 : 353.0;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 104),
          child: Column(
            children: [
              SizedBox(
                height: heroHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.image != null && item.image!.isNotEmpty
                        ? AppNetworkImage(
                            imageUrl: item.image,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.restaurant,
                            fallbackIconSize: 48,
                            backgroundColor: AppColors.surfaceContainerHigh,
                          )
                        : Container(
                            color: AppColors.surfaceContainerHigh,
                            child: const Icon(
                              Icons.restaurant,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                          ),
                    Positioned(
                      bottom: AppSpacing.md,
                      left: AppSpacing.marginMobile,
                      child: StitchGlassBadge(
                        icon: Icons.eco,
                        iconColor: AppColors.primary,
                        label: 'Pahlawan Makanan',
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -AppSpacing.xl),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 768),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.marginMobile,
                    AppSpacing.xl,
                    AppSpacing.marginMobile,
                    AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusXl),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTextStyles.headlineLg),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront,
                            size: 18,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              item.merchant?.displayName ?? 'Mitra SaveBite',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          Text(
                            Formatters.rupiah(item.rescuePrice),
                            style: AppTextStyles.headlineMd.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            Formatters.rupiah(item.originalPrice),
                            style: AppTextStyles.priceStrike,
                          ),
                          if (item.discountPct > 0)
                            StitchInfoChip(
                              label: 'Diskon ${item.discountPct}%',
                              color: AppColors.errorContainer,
                              textColor: AppColors.onErrorContainer,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(height: 1, color: AppColors.surfaceVariant),
                      const SizedBox(height: AppSpacing.lg),
                      _StitchTransparencyGrid(item: item),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Deskripsi', style: AppTextStyles.headlineSm),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        item.description?.isNotEmpty == true
                            ? item.description!
                            : 'Paket kejutan berisi makanan berkualitas dari mitra SaveBite. Dengan menyelamatkan paket ini, kamu ikut mengurangi food waste.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (item.pickupOnly) ...[
                        const SizedBox(height: AppSpacing.md),
                        _PickupOnlyChip(),
                      ],
                      if (item.merchant != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _MerchantCard(merchant: item.merchant!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + AppSpacing.sm,
          left: AppSpacing.marginMobile,
          right: AppSpacing.marginMobile,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FloatingHeaderButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
              _FloatingHeaderButton(icon: Icons.share_outlined, onTap: () {}),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: StitchBottomActionBar(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Row(
                    children: [
                      _QuantityButton(icon: Icons.remove),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '1',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelLg,
                        ),
                      ),
                      _QuantityButton(
                        icon: Icons.add,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _BuyButton(item: item)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingHeaderButton extends StatelessWidget {
  const _FloatingHeaderButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.onSurface, size: 22),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, this.color = AppColors.onSurface});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _StitchTransparencyGrid extends StatelessWidget {
  const _StitchTransparencyGrid({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TransparencyTile(
                icon: Icons.schedule,
                label: 'Stok Tersisa',
                value: 'Sisa ${item.stockRemaining}',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _TransparencyTile(
                icon: Icons.timer_off_outlined,
                label: 'Kedaluwarsa',
                value: item.expiresAt == null
                    ? '-'
                    : Formatters.relativeTime(item.expiresAt!),
                valueColor: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _TransparencyTile(
          icon: Icons.info_outline,
          label: 'Alasan Diskon',
          value: item.reason?.isNotEmpty == true
              ? item.reason!
              : 'Kelebihan produksi harian. Kualitas masih sangat baik dan layak konsumsi.',
          emphasized: true,
        ),
      ],
    );
  }
}

class _TransparencyTile extends StatelessWidget {
  const _TransparencyTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final accent = emphasized ? AppColors.primary : AppColors.onSurfaceVariant;
    return StitchSurfaceCard(
      color: emphasized
          ? AppColors.primaryContainer.withValues(alpha: 0.10)
          : AppColors.surfaceContainerLow,
      borderColor: emphasized
          ? AppColors.primaryContainer.withValues(alpha: 0.20)
          : AppColors.surfaceVariant,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(
              color: valueColor ?? AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Image + SliverAppBar ───────────────────

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      leading: _CircleBackButton(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (item.image != null && item.image!.isNotEmpty)
              AppNetworkImage(
                imageUrl: item.image,
                fit: BoxFit.cover,
                fallbackIcon: Icons.restaurant,
                fallbackIconSize: 48,
                backgroundColor: AppColors.surfaceContainerHigh,
              )
            else
              Container(
                color: AppColors.surfaceContainerHigh,
                child: const Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

            // Bottom gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),

            // Discount badge
            if (item.discountPct > 0)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56,
                right: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryContainer.withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '-${item.discountPct}%',
                    style: AppTextStyles.labelLg.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.3),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.pop(),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// ─── Flash Sale Banner ───────────────────────────

class _FlashSaleBanner extends StatelessWidget {
  const _FlashSaleBanner({required this.secondsRemaining});
  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), AppColors.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryContainer.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Flash Sale!',
            style: AppTextStyles.labelLg.copyWith(color: Colors.white),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              Formatters.countdown(secondsRemaining),
              style: AppTextStyles.labelLg.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Name Section ────────────────────────────────

class _NameSection extends StatelessWidget {
  const _NameSection({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.name, style: AppTextStyles.headlineSm),
        if (item.merchant?.category != null) ...[
          const SizedBox(height: 4),
          _CategoryChip(category: item.merchant!.category!),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final String category;

  String get _label => CategoryLabels.label(category);

  IconData get _icon => switch (category) {
    'fast_food' => Icons.fastfood,
    'bakery' => Icons.bakery_dining,
    'supermarket' => Icons.store,
    _ => Icons.storefront,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: AppColors.tertiary),
          const SizedBox(width: 4),
          Text(
            _label,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.tertiary),
          ),
        ],
      ),
    );
  }
}

// ─── Pricing Section ─────────────────────────────

class _PricingSection extends StatelessWidget {
  const _PricingSection({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Harga Rescue',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Formatters.rupiah(item.rescuePrice),
                style: AppTextStyles.price.copyWith(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Harga Asli',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Formatters.rupiah(item.originalPrice),
                style: AppTextStyles.priceStrike.copyWith(fontSize: 16),
              ),
            ],
          ),
          const Spacer(),
          if (item.discountPct > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                'Hemat ${item.discountPct}%',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }
}

// ─── Stock & Expiry Row ──────────────────────────

class _StockExpiryRow extends StatelessWidget {
  const _StockExpiryRow({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final stock = item.stockRemaining;
    final isLowStock = stock <= 3 && stock > 0;

    return Row(
      children: [
        // Stock
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLowStock
                  ? AppColors.secondaryContainer.withValues(alpha: 0.12)
                  : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
              border: Border.all(
                color: isLowStock
                    ? AppColors.secondaryContainer
                    : AppColors.surfaceContainerHighest,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: isLowStock
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  'Sisa $stock',
                  style: AppTextStyles.labelLg.copyWith(
                    color: isLowStock
                        ? AppColors.secondary
                        : AppColors.onSurface,
                  ),
                ),
                if (isLowStock)
                  Text(
                    'Segera habis!',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Expiry
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
              border: Border.all(color: AppColors.surfaceContainerHighest),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  item.expiresAt != null
                      ? Formatters.relativeTime(item.expiresAt!)
                      : '-',
                  style: AppTextStyles.labelLg,
                  textAlign: TextAlign.center,
                ),
                Text('Kadaluarsa', style: AppTextStyles.labelSm),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Pickup Only Chip ────────────────────────────

class _PickupOnlyChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_walk, size: 18, color: AppColors.info),
          const SizedBox(width: 6),
          Text(
            'Ambil Sendiri (Pickup Only)',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Merchant Card ───────────────────────────────

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({required this.merchant});
  final MerchantSummary merchant;

  @override
  Widget build(BuildContext context) {
    final rating = double.tryParse(merchant.averageRating?.toString() ?? '0');

    return GestureDetector(
      onTap: () {
        context.push('/merchants/${merchant.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
              ),
              clipBehavior: Clip.antiAlias,
              child: merchant.logo != null
                  ? AppNetworkImage(
                      imageUrl: merchant.logo,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.store,
                    )
                  : const Icon(Icons.store, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchant.displayName ?? 'Mitra SaveBite',
                    style: AppTextStyles.labelLg,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (rating != null && rating > 0) ...[
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.secondaryContainer,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (merchant.totalReviews != null) ...[
                          Text(
                            ' (${merchant.totalReviews})',
                            style: AppTextStyles.labelMd,
                          ),
                        ],
                        const SizedBox(width: 8),
                      ],
                      if (merchant.distanceKm != null)
                        Text(
                          Formatters.distance(merchant.distanceKm!),
                          style: AppTextStyles.labelMd,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Buy Button (FAB) ────────────────────────────

class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final isSoldOut = item.stockRemaining <= 0 || item.status != 'available';

    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isSoldOut
            ? null
            : () => context.push('/checkout', extra: item),
        icon: Icon(
          isSoldOut ? Icons.remove_shopping_cart : Icons.shopping_basket,
          size: 20,
        ),
        label: Text(isSoldOut ? 'Stok Habis' : 'Tambah ke Keranjang'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.surfaceContainerHigh,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}
