
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_labels.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/food_item.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../providers/browse_provider.dart';

/// Search screen — "Cari Makanan" per stitch PRD design.
///
/// Idle state: recent searches + category bento grid + trending merchants.
/// Active state: food item result grid (reuses FoodItemCard + BrowseNotifier.search).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  List<String> _recentSearches = [];
  bool _isSearching = false; // true when user has submitted a query

  // ─── Lifecycle ──────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Scroll guard (same pattern as NotificationScreen) ──

  void _onScroll() {
    if (!_isSearching) return;
    final state = ref.read(browseProvider);
    if (state.isLoading || !state.hasMore) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(browseProvider.notifier).loadMore();
    }
  }

  // ─── Recent searches (SharedPreferences) ───

  static const _recentKey = 'recent_searches';

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_recentKey) ?? [];
    if (mounted) setState(() => _recentSearches = raw);
  }

  Future<void> _saveSearch(String query) async {
    if (query.isEmpty) return;
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, _recentSearches);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
    if (mounted) setState(() => _recentSearches = []);
  }

  // ─── Search action ─────────────────────────

  void _submitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _saveSearch(trimmed);
    _focusNode.unfocus();
    setState(() => _isSearching = true);
    ref.read(browseProvider.notifier).search(trimmed);
  }

  void _searchByCategory(String category) {
    _searchCtrl.text = category;
    _submitSearch(category);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _isSearching = false);
    // Reload default browse items
    ref.read(browseProvider.notifier).loadFoodItems();
  }

  // ─── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final browseState = ref.watch(browseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Fixed header + search bar ──
            _buildHeader(),
            // ── Content ──
            Expanded(
              child: _isSearching
                  ? _buildSearchResults(browseState)
                  : _buildIdleContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header (matches home_screen pattern) ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.md,
        AppSpacing.marginMobile,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text('Cari Makanan', style: AppTextStyles.headlineSm),
          const SizedBox(height: AppSpacing.sm),
          // Search bar + filter
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDef),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _submitSearch,
                    decoration: InputDecoration(
                      hintText: 'Cari roti, nasi kotak, atau toko...',
                      hintStyle: AppTextStyles.bodyLg
                          .copyWith(color: AppColors.onSurfaceVariant),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.onSurfaceVariant, size: 20),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Filter button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusDef),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune,
                      color: AppColors.onSurface, size: 22),
                  onPressed: () => _showFilterSheet(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  // ─── Idle content (no active search) ───────

  Widget _buildIdleContent() {
    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile),
      children: [
        // Recent searches
        if (_recentSearches.isNotEmpty) ...[
          _buildRecentSearches(),
          const SizedBox(height: AppSpacing.lg),
        ],
        // Popular categories (bento grid)
        _buildCategoryBento(),
        const SizedBox(height: AppSpacing.lg),
        // Trending merchants
        _buildTrendingSection(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ─── Recent Searches ───────────────────────

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pencarian Terakhir', style: AppTextStyles.labelLg),
            GestureDetector(
              onTap: _clearRecentSearches,
              child: Text(
                'Hapus',
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _recentSearches.map((q) {
            return ActionChip(
              avatar: Icon(Icons.history,
                  size: 16, color: AppColors.onSurfaceVariant),
              label: Text(q, style: AppTextStyles.labelMd),
              backgroundColor: AppColors.surface,
              side: BorderSide(color: AppColors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
              ),
              onPressed: () => _submitSearch(q),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Category Bento Grid ───────────────────

  Widget _buildCategoryBento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori Populer', style: AppTextStyles.labelLg),
        const SizedBox(height: AppSpacing.md),
        // Large card — Bakery
        _CategoryImageCard(
          label: 'Bakery & Roti',
          subtitle: 'Diskon hingga 70%',
          icon: Icons.bakery_dining,
          imagePath: 'assets/images/category_bakery.jpg',
          height: 120,
          gradient: const [Color(0xFF006D37), Color(0xFF27AE60)],
          onTap: () => _searchByCategory('bakery'),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Two small cards
        Row(
          children: [
            Expanded(
              child: _CategoryImageCard(
                label: 'Fast Food',
                icon: Icons.fastfood,
                imagePath: 'assets/images/category_fast_food.jpg',
                height: 100,
                gradient: const [Color(0xFF904D00), Color(0xFFFFA454)],
                onTap: () => _searchByCategory('fast_food'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CategoryImageCard(
                label: 'Supermarket',
                icon: Icons.storefront,
                imagePath: 'assets/images/category_supermarket.jpg',
                height: 100,
                gradient: const [Color(0xFF006492), Color(0xFF35A1E0)],
                onTap: () => _searchByCategory('supermarket'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Trending Section ──────────────────────

  Widget _buildTrendingSection() {
    final browseState = ref.watch(browseProvider);
    // Use first 4 items' merchants as "trending"
    final merchants = <int, FoodItem>{};
    for (final item in browseState.items) {
      if (item.merchant != null && !merchants.containsKey(item.merchant!.id)) {
        merchants[item.merchant!.id] = item;
        if (merchants.length >= 4) break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trending di Sekitarmu',
            style: AppTextStyles.headlineSm),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Merchant favorit dengan sisa makanan lezat',
          style: AppTextStyles.bodyMd
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        if (merchants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                'Belum ada data merchant',
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.outline),
              ),
            ),
          )
        else
          ...merchants.values.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _TrendingMerchantCard(item: item),
              )),
      ],
    );
  }

  // ─── Search Results Grid ───────────────────

  Widget _buildSearchResults(BrowseState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return ErrorStateWidget(
        message: state.error!,
        onRetry: () => _submitSearch(_searchCtrl.text),
      );
    }

    if (state.items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: 'Tidak ditemukan',
        subtitle: 'Coba kata kunci lain atau perluas area',
      );
    }

    return GridView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < state.items.length) {
          return FoodItemCard(
            key: ValueKey(state.items[index].id),
            item: state.items[index],
          );
        }
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        );
      },
    );
  }

  // ─── Filter Bottom Sheet ───────────────────

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => const _FilterSheet(),
    );
  }
}

// ═══════════════════════════════════════════════
// PRIVATE WIDGETS
// ═══════════════════════════════════════════════

// ─── Category Image Card (bento grid) ────────

class _CategoryImageCard extends StatelessWidget {
  const _CategoryImageCard({
    required this.label,
    this.subtitle,
    required this.icon,
    this.imagePath,
    required this.height,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final String? imagePath;
  final double height;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: image or gradient fallback
              if (imagePath != null)
                Image.asset(
                  imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, st) => _gradientFallback(),
                )
              else
                _gradientFallback(),
              // Dark gradient overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      gradient.first.withValues(alpha: 0.30),
                      gradient.first.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              // Background icon (large, semi-transparent)
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(icon,
                    size: 80, color: Colors.white.withValues(alpha: 0.12)),
              ),
              // Text content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.headlineSm.copyWith(
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: AppTextStyles.labelSm.copyWith(
                          color: Colors.white.withValues(alpha: 0.90),
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gradient-only fallback when image is unavailable.
  Widget _gradientFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
    );
  }
}

// ─── Trending Merchant Card ──────────────────

class _TrendingMerchantCard extends StatelessWidget {
  const _TrendingMerchantCard({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final merchant = item.merchant!;
    final rating = double.tryParse(
            merchant.averageRating?.toString() ?? '') ??
        0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceContainer),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006D37).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Merchant image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusDef),
              color: AppColors.surfaceVariant,
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusDef),
              child: item.image != null
                  ? Image.network(item.image!, fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => _merchantPlaceholder(merchant))
                  : _merchantPlaceholder(merchant),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        merchant.displayName ?? 'Merchant',
                        style: AppTextStyles.labelLg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 12,
                                color:
                                    AppColors.onSecondaryContainer),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: AppTextStyles.labelSm.copyWith(
                                color:
                                    AppColors.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                // Category + distance
                Text(
                  [
                    if (merchant.category != null)
                      CategoryLabels.label(merchant.category!),
                    if (merchant.distanceKm != null)
                      Formatters.distance(merchant.distanceKm!),
                  ].join(' • '),
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Available badge
                Row(
                  children: [
                    Icon(Icons.eco, size: 14, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${item.quantity} Porsi Tersedia',
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _merchantPlaceholder(MerchantSummary m) {
    final icon = m.isAnonymous ? Icons.visibility_off : Icons.store;
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(child: Icon(icon, color: AppColors.outline, size: 28)),
    );
  }


}

// ─── Filter Sheet ────────────────────────────

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  String _sortBy = 'distance';
  String? _category;

  static const _sortOptions = {
    'distance': 'Terdekat',
    'price': 'Harga Terendah',
    'newest': 'Terbaru',
  };

  static const _categories = {
    'bakery': 'Bakery',
    'fast_food': 'Fast Food',
    'restaurant': 'Restaurant',
    'supermarket': 'Supermarket',
    'catering': 'Catering',
  };

  @override
  void initState() {
    super.initState();
    final state = ref.read(browseProvider);
    _sortBy = state.sortBy;
    _category = state.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile, AppSpacing.md,
          AppSpacing.marginMobile, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Filter & Urutkan', style: AppTextStyles.headlineSm),
          const SizedBox(height: AppSpacing.lg),

          // Sort
          Text('Urutkan', style: AppTextStyles.labelLg),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: _sortOptions.entries.map((e) {
              final selected = _sortBy == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => setState(() => _sortBy = e.key),
                selectedColor:
                    AppColors.primary.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.outlineVariant,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Category
          Text('Kategori', style: AppTextStyles.labelLg),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _categories.entries.map((e) {
              final selected = _category == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => setState(
                    () => _category = selected ? null : e.key),
                selectedColor:
                    AppColors.primary.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.outlineVariant,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                ref.read(browseProvider.notifier).loadFoodItems(
                      category: _category,
                      sortBy: _sortBy,
                    );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusDef),
                ),
              ),
              child: Text('Terapkan', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}
