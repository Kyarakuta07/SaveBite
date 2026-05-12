import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../models/food_item.dart';
import 'app_network_image.dart';

/// Reusable food item card — per DESIGN.md card spec.
///
/// WHY moved to shared:
/// 1. `home_screen.dart` defined this as a public class that `search_screen.dart`
///    imported. That's a cross-feature import — it creates circular dependencies
///    and means the card's location is misleading (it's "shared" but lives in a
///    single feature folder).
/// 2. The card had a `// TODO: navigate to detail` — tapping a food card did
///    NOTHING. This is a broken UX that's now fixed with `context.push`.
///
/// Usage: Used in home grid, search results, and any future food listing.
class FoodItemCard extends StatelessWidget {
  const FoodItemCard({super.key, required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006D37).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push('/food-items/${item.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + badges
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusMd)),
                    child: AppNetworkImage(
                            imageUrl: item.image,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.fastfood,
                            backgroundColor: AppColors.surfaceVariant,
                          ),
                  ),
                  // Stock badge — glass effect per DESIGN.md
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest
                            .withValues(alpha: 0.7),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border:
                            Border.all(color: AppColors.surfaceContainerHighest),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule,
                              size: 12, color: AppColors.onSurface),
                          const SizedBox(width: 4),
                          Text(
                            'Sisa ${item.stockRemaining}',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Discount badge
                  if (item.discountPct > 0)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          '${item.discountPct}% OFF',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food name
                    Text(
                      item.name,
                      style: AppTextStyles.labelLg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Merchant name
                    Text(
                      item.merchant?.displayName ?? 'Merchant',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            Formatters.rupiah(item.rescuePrice),
                            style: AppTextStyles.headlineSm.copyWith(
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          Formatters.rupiah(item.originalPrice),
                          style: AppTextStyles.priceStrike.copyWith(
                            fontSize: 12,
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
      ),
    );
  }
}
