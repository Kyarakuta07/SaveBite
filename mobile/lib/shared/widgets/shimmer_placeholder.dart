import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';

/// Reusable shimmer loading placeholder.
///
/// WHY a shared widget: The same `Shimmer.fromColors` pattern with identical
/// `baseColor` / `highlightColor` was copy-pasted across 3 screens
/// (home, orders, wallet). Changing the shimmer palette required touching
/// every file. Now there's a single source of truth.
///
/// Usage:
/// ```dart
/// // Grid shimmer (food items)
/// ShimmerPlaceholder.grid(count: 6);
///
/// // List shimmer (orders, transactions)
/// ShimmerPlaceholder.list(count: 4, itemHeight: 120);
///
/// // Single card shimmer
/// ShimmerPlaceholder(height: 200);
/// ```
class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({
    super.key,
    this.height = 120,
    this.width,
    this.borderRadius,
  });

  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerHigh,
      highlightColor: AppColors.surfaceContainerLowest,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  /// Grid of shimmer cards — used for food item grids.
  static Widget grid({int count = 6}) {
    return SliverPadding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, _) => const ShimmerPlaceholder(),
          childCount: count,
        ),
      ),
    );
  }

  /// Vertical list of shimmer bars — used for orders, transactions.
  static Widget list({int count = 4, double itemHeight = 120}) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ShimmerPlaceholder(height: itemHeight),
      ),
    );
  }

  /// Sliver version of the list — for use in CustomScrollView.
  static Widget sliverList({int count = 4, double itemHeight = 72}) {
    return SliverPadding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, _) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ShimmerPlaceholder(height: itemHeight),
          ),
          childCount: count,
        ),
      ),
    );
  }
}
