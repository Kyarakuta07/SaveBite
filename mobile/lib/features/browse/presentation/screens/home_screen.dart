import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_labels.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/food_item.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../providers/browse_provider.dart';

/// Home screen — Beranda per stitch PRD design.
///
/// Structure: Header → Location → Search → Category grid →
///            Flash Sale (horizontal) → "Dekat Anda" (merchant list) →
///            Food grid (browse feed).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(browseProvider.notifier).loadFoodItems();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(browseProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browseState = ref.watch(browseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(browseProvider.notifier).loadFoodItems(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Header (per beranda screen.png) ──────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      // User avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceVariant,
                        ),
                        child: const ClipOval(
                          child: Icon(
                            Icons.person,
                            size: 20,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Brand name
                      Text(
                        'SaveBite',
                        style: AppTextStyles.headlineMd.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      // Notification bell
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: AppColors.primary,
                        onPressed: () => context.push('/notifications'),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Location selector + Search ──────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location
                      GestureDetector(
                        onTap: () {
                          // TODO: open location picker
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Jakarta Selatan',
                              style: AppTextStyles.labelLg,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.expand_more,
                              size: 20,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusDef,
                          ),
                          border: Border.all(color: AppColors.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari makanan berkualitas...',
                            hintStyle: AppTextStyles.bodyLg.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.onSurfaceVariant,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          onSubmitted: (q) =>
                              ref.read(browseProvider.notifier).search(q),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // ── Category Grid (4-column circular icons) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CategoryCircle(
                        label: 'Fast Food',
                        icon: Icons.fastfood,
                        isSelected: browseState.selectedCategory == 'fast_food',
                        onTap: () => ref
                            .read(browseProvider.notifier)
                            .setCategory(
                              browseState.selectedCategory == 'fast_food'
                                  ? null
                                  : 'fast_food',
                            ),
                      ),
                      _CategoryCircle(
                        label: 'Bakery',
                        icon: Icons.bakery_dining,
                        isSelected: browseState.selectedCategory == 'bakery',
                        onTap: () => ref
                            .read(browseProvider.notifier)
                            .setCategory(
                              browseState.selectedCategory == 'bakery'
                                  ? null
                                  : 'bakery',
                            ),
                      ),
                      _CategoryCircle(
                        label: 'Supermarket',
                        icon: Icons.storefront,
                        isSelected:
                            browseState.selectedCategory == 'supermarket',
                        onTap: () => ref
                            .read(browseProvider.notifier)
                            .setCategory(
                              browseState.selectedCategory == 'supermarket'
                                  ? null
                                  : 'supermarket',
                            ),
                      ),
                      _CategoryCircle(
                        label: 'Nearby',
                        icon: Icons.near_me,
                        isSelected: browseState.selectedCategory == 'nearby',
                        onTap: () => ref
                            .read(browseProvider.notifier)
                            .setCategory(
                              browseState.selectedCategory == 'nearby'
                                  ? null
                                  : 'nearby',
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // ── Food Grid ────────────────────
              if (browseState.items.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _FlashSaleSection(items: browseState.items),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
                SliverToBoxAdapter(
                  child: _NearYouSection(items: browseState.items),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile,
                    ),
                    child: StitchSectionHeader(
                      title: 'Semua Makanan',
                      trailing: const Icon(
                        Icons.tune,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
              ],

              if (browseState.isLoading && browseState.items.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (_, idx) => const ShimmerPlaceholder(),
                      childCount: 6,
                    ),
                  ),
                )
              else if (browseState.error != null && browseState.items.isEmpty)
                SliverFillRemaining(
                  child: ErrorStateWidget(
                    message: browseState.error!,
                    onRetry: () =>
                        ref.read(browseProvider.notifier).loadFoodItems(),
                  ),
                )
              else if (browseState.items.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.food_bank_outlined,
                    title: 'Belum ada makanan di sekitarmu',
                    subtitle: 'Coba perluas radius pencarian',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < browseState.items.length) {
                          return FoodItemCard(
                            key: ValueKey(browseState.items[index].id),
                            item: browseState.items[index],
                          );
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
                      childCount:
                          browseState.items.length +
                          (browseState.hasMore ? 1 : 0),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Category Circle (per beranda design — 4-column grid) ─────

class _CategoryCircle extends StatelessWidget {
  const _CategoryCircle({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppColors.onPrimaryContainer
                  : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FlashSaleSection extends StatelessWidget {
  const _FlashSaleSection({required this.items});
  final List<FoodItem> items;

  @override
  Widget build(BuildContext context) {
    final flashItems = [
      ...items.where((item) => item.isFlashSale),
      ...items.where((item) => !item.isFlashSale),
    ].take(5).toList();

    if (flashItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: StitchShadows.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
            ),
            child: Row(
              children: [
                Text('Flash Sale', style: AppTextStyles.headlineSm),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.onErrorContainer,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '01:45:20',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Lihat Semua',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 228,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
              ),
              itemCount: flashItems.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 220,
                  child: FoodItemCard(item: flashItems[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NearYouSection extends StatelessWidget {
  const _NearYouSection({required this.items});
  final List<FoodItem> items;

  @override
  Widget build(BuildContext context) {
    final merchants = <int, FoodItem>{};
    for (final item in items) {
      final merchant = item.merchant;
      if (merchant != null && !merchants.containsKey(merchant.id)) {
        merchants[merchant.id] = item;
      }
      if (merchants.length >= 3) break;
    }

    if (merchants.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Column(
        children: [
          const StitchSectionHeader(
            title: 'Dekat Anda',
            trailing: Icon(Icons.tune, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          ...merchants.values.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _NearbyMerchantCard(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyMerchantCard extends StatelessWidget {
  const _NearbyMerchantCard({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final merchant = item.merchant!;
    final rating =
        double.tryParse(merchant.averageRating?.toString() ?? '') ?? 0;
    final category = merchant.category == null
        ? null
        : CategoryLabels.label(merchant.category!);

    return GestureDetector(
      onTap: () => context.push('/merchants/${merchant.id}'),
      child: StitchSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
              child: SizedBox(
                width: 96,
                height: 96,
                child: item.image == null
                    ? _MerchantFallback(isAnonymous: merchant.isAnonymous)
                    : AppNetworkImage(
                        imageUrl: item.image,
                        fit: BoxFit.cover,
                        fallbackIcon: merchant.isAnonymous
                            ? Icons.help_center_outlined
                            : Icons.storefront,
                        backgroundColor: AppColors.surfaceVariant,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                merchant.displayName ?? 'Mitra SaveBite',
                                style: AppTextStyles.labelLg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (merchant.isAnonymous)
                              const Icon(
                                Icons.verified,
                                size: 14,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            if (rating > 0) ...[
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: AppTextStyles.labelMd.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const _Dot(),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Text(
                              merchant.distanceKm == null
                                  ? 'Dekat Anda'
                                  : Formatters.distance(merchant.distanceKm!),
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (category != null)
                          StitchInfoChip(
                            label: category,
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.2,
                            ),
                            textColor: AppColors.primary,
                            borderColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        if (merchant.isAnonymous)
                          const StitchInfoChip(label: 'Magic Bag'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantFallback extends StatelessWidget {
  const _MerchantFallback({required this.isAnonymous});
  final bool isAnonymous;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(
              isAnonymous ? Icons.help_center_outlined : Icons.storefront,
              color: AppColors.outline,
              size: 40,
            ),
          ),
          if (isAnonymous)
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Kejutan',
                  style: AppTextStyles.labelSm.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.outlineVariant,
      ),
    );
  }
}
