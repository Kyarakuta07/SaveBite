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
import '../../../social/providers/social_provider.dart';
import '../../providers/browse_provider.dart';

/// Public merchant profile screen, matched to Stitch PRD `savebitetokomerchant`.
class MerchantProfileScreen extends ConsumerWidget {
  const MerchantProfileScreen({required this.merchantId, super.key});
  final int merchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(merchantProfileProvider(merchantId));
    final asyncReviews = ref.watch(merchantReviewsProvider(merchantId));
    final asyncItems = ref.watch(merchantFoodItemsProvider(merchantId));
    final followsState = ref.watch(followsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: asyncProfile.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(merchantProfileProvider(merchantId)),
        ),
        data: (profile) {
          final isFollowing = followsState.follows.any(
            (f) =>
                (f['merchant_id'] as int?) == merchantId ||
                (f['id'] as int?) == merchantId,
          );

          Future<void> toggleFollow() async {
            if (isFollowing) {
              await ref.read(followsProvider.notifier).unfollow(merchantId);
            } else {
              await ref.read(followsProvider.notifier).follow(merchantId);
            }
          }

          return _MerchantProfileBody(
            profile: profile,
            reviews: asyncReviews,
            items: asyncItems,
            isFollowing: isFollowing,
            isLoadingFollow: followsState.isLoading,
            onFollowToggle: toggleFollow,
          );
        },
      ),
    );
  }
}

class _MerchantProfileBody extends StatelessWidget {
  const _MerchantProfileBody({
    required this.profile,
    required this.reviews,
    required this.items,
    required this.isFollowing,
    required this.isLoadingFollow,
    required this.onFollowToggle,
  });

  final Map<String, dynamic> profile;
  final AsyncValue<
    ({List<Map<String, dynamic>> reviews, Map<String, dynamic> meta})
  >
  reviews;
  final AsyncValue<List<FoodItem>> items;
  final bool isFollowing;
  final bool isLoadingFollow;
  final VoidCallback onFollowToggle;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _MerchantHero(
            profile: profile,
            isFollowing: isFollowing,
            isLoadingFollow: isLoadingFollow,
            onFollowToggle: onFollowToggle,
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AddressCard(profile: profile),
                    const SizedBox(height: AppSpacing.lg),
                    _StatsGrid(profile: profile),
                    const SizedBox(height: AppSpacing.xl),
                    const _MerchantTabs(),
                    const SizedBox(height: AppSpacing.md),
                    _AvailableItemsSection(items: items),
                    const SizedBox(height: AppSpacing.xl),
                    _ReviewsSection(reviews: reviews),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MerchantHero extends StatelessWidget {
  const _MerchantHero({
    required this.profile,
    required this.isFollowing,
    required this.isLoadingFollow,
    required this.onFollowToggle,
  });

  final Map<String, dynamic> profile;
  final bool isFollowing;
  final bool isLoadingFollow;
  final VoidCallback onFollowToggle;

  @override
  Widget build(BuildContext context) {
    final displayName = profile['display_name'] as String? ?? 'Mitra SaveBite';
    final category = profile['category'] as String?;
    final logo = profile['logo'] as String?;
    final cover =
        (profile['cover_image'] as String?) ??
        (profile['cover'] as String?) ??
        (profile['banner'] as String?);
    final totalReviews = profile['total_reviews'] as int? ?? 0;

    return SizedBox(
      height: 342,
      child: Stack(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (cover != null && cover.isNotEmpty)
                  AppNetworkImage(
                    imageUrl: cover,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.storefront,
                    backgroundColor: AppColors.surfaceContainerHigh,
                  )
                else
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.tertiaryContainer,
                        ],
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.20),
                        Colors.transparent,
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
                _HeroActionButton(
                  icon: Icons.arrow_back,
                  onTap: () => context.pop(),
                ),
                _HeroActionButton(icon: Icons.share_outlined, onTap: () {}),
              ],
            ),
          ),
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _MerchantLogo(logo: logo),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.headlineMd
                                              .copyWith(color: Colors.white),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.verified,
                                        size: 20,
                                        color: AppColors.tertiaryContainer,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    category == null
                                        ? 'Mitra SaveBite'
                                        : CategoryLabels.label(category),
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 14,
                                        color: AppColors.secondaryContainer,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '$totalReviews ulasan',
                                        style: AppTextStyles.labelSm.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      StitchSurfaceCard(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        radius: AppSpacing.radiusMd,
                        borderColor: Colors.transparent,
                        shadow: StitchShadows.card,
                        child: SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: isLoadingFollow ? null : onFollowToggle,
                            icon: Icon(
                              isFollowing ? Icons.check : Icons.add,
                              size: 16,
                            ),
                            label: Text(isFollowing ? 'Mengikuti' : 'Ikuti'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              elevation: 0,
                              textStyle: AppTextStyles.labelLg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _MerchantLogo extends StatelessWidget {
  const _MerchantLogo({required this.logo});
  final String? logo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.surfaceContainerLowest, width: 4),
        boxShadow: StitchShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: logo != null && logo!.isNotEmpty
          ? AppNetworkImage(
              imageUrl: logo,
              fit: BoxFit.cover,
              fallbackIcon: Icons.storefront,
            )
          : const Icon(Icons.storefront, size: 42, color: AppColors.primary),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final isAnonymous = profile['is_anonymous'] as bool? ?? false;
    final address = isAnonymous
        ? 'Lokasi detail disembunyikan'
        : profile['address'] as String? ?? 'Alamat belum tersedia';

    return StitchSurfaceCard(
      shadow: const [],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alamat',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(address, style: AppTextStyles.bodyMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final rating =
        double.tryParse((profile['average_rating'] ?? '').toString()) ?? 0;
    final totalReviews = profile['total_reviews'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.star,
            iconColor: AppColors.secondary,
            value: rating > 0 ? rating.toStringAsFixed(1) : '-',
            label: 'Rating',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: _StatTile(
            icon: Icons.near_me_outlined,
            iconColor: AppColors.tertiary,
            value: '1.2',
            label: 'km Jarak',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: Icons.rate_review_outlined,
            iconColor: AppColors.primary,
            value: '$totalReviews',
            label: 'Ulasan',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return StitchSurfaceCard(
      padding: const EdgeInsets.all(12),
      color: AppColors.surfaceContainerLow,
      borderColor: AppColors.surfaceVariant.withValues(alpha: 0.50),
      shadow: const [],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: AppSpacing.xs),
              Text(value, style: AppTextStyles.headlineSm),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantTabs extends StatelessWidget {
  const _MerchantTabs();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _MerchantTab(label: 'Tersedia', active: true),
        SizedBox(width: AppSpacing.lg),
        _MerchantTab(label: 'Ulasan'),
      ],
    );
  }
}

class _MerchantTab extends StatelessWidget {
  const _MerchantTab({required this.label, this.active = false});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            label,
            style: AppTextStyles.labelLg.copyWith(
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailableItemsSection extends StatelessWidget {
  const _AvailableItemsSection({required this.items});
  final AsyncValue<List<FoodItem>> items;

  @override
  Widget build(BuildContext context) {
    return items.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, _) => Text(
        'Gagal memuat makanan: $err',
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
      ),
      data: (foodItems) {
        if (foodItems.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: Text(
                'Belum ada makanan tersedia',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return Column(
          children: foodItems
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _MerchantFoodCard(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MerchantFoodCard extends StatelessWidget {
  const _MerchantFoodCard({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/food-items/${item.id}'),
      child: StitchSurfaceCard(
        padding: EdgeInsets.zero,
        borderColor: AppColors.surfaceVariant.withValues(alpha: 0.30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
              child: SizedBox(
                height: 192,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(
                      imageUrl: item.image,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.bakery_dining,
                      backgroundColor: AppColors.surfaceContainerHigh,
                    ),
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StitchGlassBadge(
                            icon: Icons.schedule,
                            iconColor: AppColors.tertiary,
                            label: item.producedAt == null
                                ? 'Waktu Produksi'
                                : 'Waktu Produksi: ${_shortTime(item.producedAt!)}',
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          StitchGlassBadge(
                            icon: Icons.hourglass_bottom,
                            iconColor: AppColors.error,
                            label: item.expiresAt == null
                                ? 'Kedaluwarsa'
                                : 'Kedaluwarsa: ${Formatters.relativeTime(item.expiresAt!)}',
                          ),
                        ],
                      ),
                    ),
                    if (item.discountPct > 0)
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusDef,
                            ),
                            boxShadow: StitchShadows.card,
                          ),
                          child: Text(
                            '-${item.discountPct}%',
                            style: AppTextStyles.labelLg.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTextStyles.headlineSm,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StitchInfoChip(
                        label: 'Sisa ${item.stockRemaining}',
                        color: item.stockRemaining <= 1
                            ? AppColors.errorContainer
                            : AppColors.surfaceVariant,
                        textColor: item.stockRemaining <= 1
                            ? AppColors.onErrorContainer
                            : AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                  if (item.description?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.description!,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.rupiah(item.originalPrice),
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            Formatters.rupiah(item.rescuePrice),
                            style: AppTextStyles.headlineMd.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/food-items/${item.id}'),
                        icon: const Icon(Icons.shopping_cart, size: 18),
                        label: const Text('Pesan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          textStyle: AppTextStyles.labelLg,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews});
  final AsyncValue<
    ({List<Map<String, dynamic>> reviews, Map<String, dynamic> meta})
  >
  reviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('Ulasan Pelanggan', style: AppTextStyles.labelLg),
            const Spacer(),
            reviews.maybeWhen(
              data: (data) => Text(
                '${data.meta['total'] ?? data.reviews.length} ulasan',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        reviews.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Text(
            'Gagal memuat ulasan: $err',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
          ),
          data: (data) {
            if (data.reviews.isEmpty) return const _EmptyReviews();
            return Column(
              children: data.reviews
                  .map(
                    (review) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ReviewCard(review: review),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context) {
    final name = review['reviewer_name'] as String? ?? 'Anonim';
    final rating = review['rating'] as int? ?? 0;
    final comment = review['comment'] as String?;
    final createdAt = review['created_at'] != null
        ? DateTime.tryParse(review['created_at'].toString())
        : null;

    return StitchSurfaceCard(
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceContainerHigh,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.labelLg),
                    if (createdAt != null)
                      Text(
                        Formatters.relativeTime(createdAt),
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < rating ? Icons.star : Icons.star_outline,
                size: 16,
                color: i < rating
                    ? AppColors.secondaryContainer
                    : AppColors.surfaceContainerHighest,
              ),
            ),
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(comment, style: AppTextStyles.bodyMd),
          ],
        ],
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Belum ada ulasan',
            style: AppTextStyles.labelLg.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Jadilah yang pertama memberikan ulasan!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Gagal memuat profil toko', style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

String _shortTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
