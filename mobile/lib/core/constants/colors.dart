import 'package:flutter/material.dart';

/// SaveBite brand color palette — Verdant Harvest design system.
///
/// Based on stitch_prd_application_design/verdant_harvest/DESIGN.md
/// Material 3 tonal palette with green/orange/blue triad.
class AppColors {
  const AppColors._();

  // Primary — Leaf Green (brand identity, success, "Rescue" actions)
  static const Color primary = Color(0xFF006D37);
  static const Color primaryContainer = Color(0xFF27AE60);
  static const Color onPrimaryContainer = Color(0xFF00391A);
  static const Color primaryLight = Color(0xFF61DE8A); // inverse-primary

  // Secondary — Sunburst Orange (deals, discounts, urgency)
  static const Color secondary = Color(0xFF904D00);
  static const Color secondaryContainer = Color(0xFFFFA454);
  static const Color onSecondaryContainer = Color(0xFF713B00);

  // Tertiary — Sky Blue (informational, trust badges)
  static const Color tertiary = Color(0xFF006492);
  static const Color tertiaryContainer = Color(0xFF35A1E0);

  // Surface & Background (Material 3 tonal hierarchy)
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);
  static const Color surfaceVariant = Color(0xFFE1E3E4);

  // On-surface
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF3D4A3F);
  static const Color textSecondary = Color(0xFF6D7A6E); // = outline

  // Outline
  static const Color outline = Color(0xFF6D7A6E);
  static const Color outlineVariant = Color(0xFFBCCABC);
  static const Color divider = Color(0xFFBCCABC); // = outlineVariant

  // Semantic
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFFFA454);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color info = Color(0xFF006492);

  // Order status
  static const Color statusPending = Color(0xFF6D7A6E);
  static const Color statusConfirmed = Color(0xFF006492);
  static const Color statusDelivered = Color(0xFF904D00);
  static const Color statusCompleted = Color(0xFF006D37);
  static const Color statusCancelled = Color(0xFFBA1A1A);
}
