/// Merchant category label mappings (Indonesian locale).
///
/// WHY shared: This switch expression was duplicated in 3+ screens
/// (`merchant_profile_screen.dart`, `search_screen.dart`, `followed_stores_screen.dart`).
/// A single source of truth prevents label inconsistencies when new
/// categories are added on the backend.
class CategoryLabels {
  const CategoryLabels._();

  /// Human-friendly label for a backend merchant category slug.
  ///
  /// Categories with emoji prefixes are used in contexts where extra
  /// visual emphasis is needed (e.g. merchant profile header).
  static String label(String category) => switch (category) {
        'bakery' => 'Bakery',
        'fast_food' => 'Fast Food',
        'restaurant' => 'Restaurant',
        'supermarket' => 'Supermarket',
        'catering' => 'Catering',
        _ => category,
      };

  /// Label with emoji prefix — use in prominent display contexts.
  static String labelWithEmoji(String category) => switch (category) {
        'fast_food' => '🍔 Fast Food',
        'bakery' => '🥐 Bakery',
        'supermarket' => '🏬 Supermarket',
        'restaurant' => '🍽️ Restaurant',
        'catering' => '🍱 Catering',
        _ => category,
      };
}
