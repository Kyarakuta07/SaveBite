import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/theme/app_theme.dart';

class StitchShadows {
  const StitchShadows._();

  static List<BoxShadow> get ambient => [
    BoxShadow(
      color: const Color(0xFF006D37).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 3),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get bottomBar => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, -4),
    ),
  ];
}

class StitchTopBar extends StatelessWidget {
  const StitchTopBar({
    super.key,
    this.leading,
    this.title = 'SaveBite',
    this.trailing,
    this.onNotifications,
  });

  final Widget? leading;
  final String title;
  final Widget? trailing;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      color: AppColors.surface,
      child: Row(
        children: [
          leading ??
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(Icons.person, size: 20, color: AppColors.outline),
              ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
          ),
          const Spacer(),
          trailing ??
              IconButton(
                onPressed:
                    onNotifications ?? () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.primary,
                style: IconButton.styleFrom(
                  fixedSize: const Size(40, 40),
                  backgroundColor: Colors.transparent,
                  shape: const CircleBorder(),
                ),
              ),
        ],
      ),
    );
  }
}

class StitchSearchField extends StatelessWidget {
  const StitchSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
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
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        style: AppTextStyles.bodyLg,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodyLg.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class StitchSurfaceCard extends StatelessWidget {
  const StitchSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppSpacing.radiusMd,
    this.color = AppColors.surfaceContainerLowest,
    this.borderColor = AppColors.surfaceVariant,
    this.shadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color borderColor;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow ?? StitchShadows.card,
      ),
      child: child,
    );
  }
}

class StitchSectionHeader extends StatelessWidget {
  const StitchSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.headlineSm),
        const Spacer(),
        if (trailing != null)
          trailing!
        else if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: AppTextStyles.labelMd,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class StitchGlassBadge extends StatelessWidget {
  const StitchGlassBadge({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = AppColors.onSurface,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
            border: Border.all(color: AppColors.surfaceContainerHighest),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StitchInfoChip extends StatelessWidget {
  const StitchInfoChip({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.surfaceVariant,
    this.textColor = AppColors.onSurfaceVariant,
    this.borderColor,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label, style: AppTextStyles.labelSm.copyWith(color: textColor)),
        ],
      ),
    );
  }
}

class StitchBottomActionBar extends StatelessWidget {
  const StitchBottomActionBar({
    super.key,
    required this.child,
    this.maxWidth = 640,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.md,
        AppSpacing.marginMobile,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: const Border(top: BorderSide(color: AppColors.surfaceVariant)),
        boxShadow: StitchShadows.bottomBar,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
