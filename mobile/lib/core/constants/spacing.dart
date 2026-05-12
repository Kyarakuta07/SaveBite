/// Spacing & sizing tokens — Verdant Harvest design system.
///
/// Based on 8px rhythm. See DESIGN.md `spacing` and `rounded` sections.
class AppSpacing {
  const AppSpacing._();

  // ─── Spacing tokens ───
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Mobile grid
  static const double marginMobile = 16.0; // outer margin
  static const double gutterMobile = 12.0; // column gutter

  // ─── Border radius tokens (from DESIGN.md `rounded`) ───
  static const double radiusSm = 4.0; // 0.25rem — small chips, tags
  static const double radiusDef = 8.0; // 0.5rem — buttons, inputs, standard cards
  static const double radiusMd = 12.0; // 0.75rem — medium containers
  static const double radiusLg = 16.0; // 1rem   — featured food cards, bottom sheets
  static const double radiusXl = 24.0; // 1.5rem — large containers, modals
  static const double radiusFull = 9999.0; // pills, circular icons
}
