import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../shared/models/food_item.dart';
import '../data/repositories/browse_repository.dart';

// ─── Browse State ────────────────────────────

class BrowseState {
  const BrowseState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasMore = true,
    this.selectedCategory,
    this.searchQuery,
    this.sortBy = 'distance',
  });

  final List<FoodItem> items;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int lastPage;
  final bool hasMore;
  final String? selectedCategory;
  final String? searchQuery;
  final String sortBy;

  BrowseState copyWith({
    List<FoodItem>? items,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? lastPage,
    bool? hasMore,
    String? selectedCategory,
    String? searchQuery,
    String? sortBy,
  }) => BrowseState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    currentPage: currentPage ?? this.currentPage,
    lastPage: lastPage ?? this.lastPage,
    hasMore: hasMore ?? this.hasMore,
    selectedCategory: selectedCategory ?? this.selectedCategory,
    searchQuery: searchQuery ?? this.searchQuery,
    sortBy: sortBy ?? this.sortBy,
  );
}

// ─── Browse Notifier ─────────────────────────

final browseProvider = StateNotifierProvider<BrowseNotifier, BrowseState>((
  ref,
) {
  return BrowseNotifier(ref.read(browseRepositoryProvider));
});

class BrowseNotifier extends StateNotifier<BrowseState> {
  BrowseNotifier(this._repo) : super(const BrowseState());

  final BrowseRepository _repo;

  /// Load first page.
  Future<void> loadFoodItems({
    double? lat,
    double? lng,
    String? category,
    String? search,
    String? sortBy,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedCategory: category,
      searchQuery: search,
      sortBy: sortBy,
    );

    final result = await _repo.getFoodItems(
      lat: lat,
      lng: lng,
      category: category ?? state.selectedCategory,
      search: search ?? state.searchQuery,
      sortBy: sortBy ?? state.sortBy,
      page: 1,
    );

    switch (result) {
      case Success(:final data):
        final currentPage = data.meta['current_page'] as int? ?? 1;
        final lastPage = data.meta['last_page'] as int? ?? 1;
        state = state.copyWith(
          items: data.items,
          isLoading: false,
          currentPage: currentPage,
          lastPage: lastPage,
          hasMore: currentPage < lastPage,
        );
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
    }
  }

  /// Load next page (infinite scroll).
  Future<void> loadMore({double? lat, double? lng}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final nextPage = state.currentPage + 1;

    final result = await _repo.getFoodItems(
      lat: lat,
      lng: lng,
      category: state.selectedCategory,
      search: state.searchQuery,
      sortBy: state.sortBy,
      page: nextPage,
    );

    switch (result) {
      case Success(:final data):
        final currentPage = data.meta['current_page'] as int? ?? nextPage;
        final lastPage = data.meta['last_page'] as int? ?? 1;
        state = state.copyWith(
          items: [...state.items, ...data.items],
          isLoading: false,
          currentPage: currentPage,
          lastPage: lastPage,
          hasMore: currentPage < lastPage,
        );
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
    }
  }

  /// Filter by category.
  Future<void> setCategory(String? category, {double? lat, double? lng}) async {
    await loadFoodItems(
      lat: lat,
      lng: lng,
      category: category,
      search: state.searchQuery,
      sortBy: state.sortBy,
    );
  }

  /// Search by keyword.
  Future<void> search(String query, {double? lat, double? lng}) async {
    await loadFoodItems(
      lat: lat,
      lng: lng,
      search: query,
      category: state.selectedCategory,
      sortBy: state.sortBy,
    );
  }
}

// ─── Flash Sale Provider ─────────────────────

final flashSaleProvider = FutureProvider<List<FoodItem>>((ref) async {
  final repo = ref.read(browseRepositoryProvider);
  final result = await repo.getFlashSaleItems();
  switch (result) {
    case Success(:final data):
      return data;
    case Failure(:final message):
      throw Exception(message);
  }
});

// ─── Food Item Detail Provider ───────────────

final foodItemDetailProvider = FutureProvider.family<FoodItem, int>((
  ref,
  id,
) async {
  final repo = ref.read(browseRepositoryProvider);
  final result = await repo.getFoodItemDetail(id);
  switch (result) {
    case Success(:final data):
      return data;
    case Failure(:final message):
      throw Exception(message);
  }
});

// ─── Merchant Profile Provider ───────────────

/// Fetches the full public merchant profile (includes address,
/// operational_hours, and other fields not present in MerchantSummary).
/// WHY separate from MerchantSummary: the profile endpoint returns
/// address/lat/lng/operational_hours that the list endpoint omits.
final merchantProfileProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, merchantId) async {
      final repo = ref.read(browseRepositoryProvider);
      final result = await repo.getMerchantProfile(merchantId);
      switch (result) {
        case Success(:final data):
          return data;
        case Failure(:final message):
          throw Exception(message);
      }
    });

// ─── Merchant Reviews Provider ───────────────

/// Fetches paginated reviews for a merchant.
/// WHY FutureProvider: reviews are read-only in this screen; no mutation needed.
/// For load-more, the screen will invalidate with a new page param.
final merchantReviewsProvider =
    FutureProvider.family<
      ({List<Map<String, dynamic>> reviews, Map<String, dynamic> meta}),
      int
    >((ref, merchantId) async {
      final repo = ref.read(browseRepositoryProvider);
      final result = await repo.getMerchantReviews(merchantId);
      switch (result) {
        case Success(:final data):
          return data;
        case Failure(:final message):
          throw Exception(message);
      }
    });

final merchantFoodItemsProvider = FutureProvider.family<List<FoodItem>, int>((
  ref,
  merchantId,
) async {
  final repo = ref.read(browseRepositoryProvider);
  final result = await repo.getFoodItems(
    merchantId: merchantId,
    sortBy: 'newest',
  );
  switch (result) {
    case Success(:final data):
      return data.items;
    case Failure(:final message):
      throw Exception(message);
  }
});
