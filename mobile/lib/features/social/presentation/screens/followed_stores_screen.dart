import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_labels.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../social/providers/social_provider.dart';

/// Followed stores / "Toko Diikuti" screen.
///
/// Route: `/follows` (push from profile menu).
/// Displays the user's followed merchants with unfollow capability.
class FollowedStoresScreen extends ConsumerStatefulWidget {
  const FollowedStoresScreen({super.key});

  @override
  ConsumerState<FollowedStoresScreen> createState() =>
      _FollowedStoresScreenState();
}

class _FollowedStoresScreenState extends ConsumerState<FollowedStoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(followsProvider.notifier).loadFollows();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(followsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Toko Diikuti'),
        titleTextStyle: AppTextStyles.headlineSm
            .copyWith(color: AppColors.primary),
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(followsProvider.notifier).loadFollows(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(FollowsState state) {
    if (state.isLoading && state.follows.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: ShimmerPlaceholder(height: 80),
          ),
        ),
      );
    }

    if (state.error != null && state.follows.isEmpty) {
      return Center(
        child: ErrorStateWidget(
          message: state.error!,
          onRetry: () =>
              ref.read(followsProvider.notifier).loadFollows(),
        ),
      );
    }

    if (state.follows.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.favorite_outline,
          title: 'Belum ada toko diikuti',
          subtitle: 'Follow toko favoritmu agar tidak ketinggalan promo',
          iconSize: 64,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      itemCount: state.follows.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final merchant = state.follows[index];
        return _FollowedMerchantCard(
          merchant: merchant,
          onTap: () {
            final id = merchant['id'] as int? ??
                merchant['merchant_id'] as int?;
            if (id != null) context.push('/merchants/$id');
          },
          onUnfollow: () async {
            final id = merchant['id'] as int? ??
                merchant['merchant_id'] as int?;
            if (id != null) {
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(followsProvider.notifier).unfollow(id);
              messenger.showSnackBar(
                const SnackBar(content: Text('Berhenti mengikuti')),
              );
            }
          },
        );
      },
    );
  }
}

// ─── Merchant Card ───────────────────────────

class _FollowedMerchantCard extends StatelessWidget {
  const _FollowedMerchantCard({
    required this.merchant,
    required this.onTap,
    required this.onUnfollow,
  });

  final Map<String, dynamic> merchant;
  final VoidCallback onTap;
  final VoidCallback onUnfollow;

  @override
  Widget build(BuildContext context) {
    final name = merchant['name'] as String? ??
        merchant['business_name'] as String? ??
        'Merchant';
    final category = merchant['category'] as String?;
    final image = merchant['logo'] as String? ??
        merchant['image'] as String?;
    final rating = double.tryParse(
            (merchant['average_rating'] ?? '').toString()) ??
        0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.surfaceContainer),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusDef),
              child: SizedBox(
                width: 56,
                height: 56,
                child: image != null
                    ? AppNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.store,
                      )
                    : _placeholder(name),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTextStyles.labelLg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (category != null)
                        Text(
                          CategoryLabels.label(category),
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      if (category != null && rating > 0)
                        Text(' • ',
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            )),
                      if (rating > 0) ...[
                        Icon(Icons.star,
                            size: 12,
                            color: AppColors.secondaryContainer),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Unfollow button
            TextButton(
              onPressed: onUnfollow,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Batal Ikuti',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(String name) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }


}
