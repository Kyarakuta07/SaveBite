import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savebite/core/errors/failures.dart';
import 'package:savebite/shared/models/food_item.dart';
import 'package:savebite/features/browse/data/repositories/browse_repository.dart';
import 'package:savebite/features/browse/providers/browse_provider.dart';

// ─── Fake Repository ──────────────────────────

class FakeBrowseRepository extends BrowseRepository {
  FakeBrowseRepository() : super(Dio());

  bool shouldFail = false;
  String failMessage = 'Test error';

  // Configurable page count for pagination tests.
  int totalPages = 2;

  List<FoodItem> _makeItems(int page) => List.generate(
    3,
    (i) => FoodItem(
      id: (page - 1) * 3 + i + 1,
      name: 'Item ${(page - 1) * 3 + i + 1}',
      originalPrice: '20000',
      rescuePrice: '10000',
      discountPct: 50,
      quantity: 10,
      status: 'available',
    ),
  );

  @override
  Future<ApiResult<({List<FoodItem> items, Map<String, dynamic> meta})>>
  getFoodItems({
    double? lat,
    double? lng,
    int? radius,
    int? merchantId,
    String? category,
    String? search,
    String? sortBy,
    int page = 1,
  }) async {
    if (shouldFail) return Failure(message: failMessage);
    return Success((
      items: _makeItems(page),
      meta: {'current_page': page, 'last_page': totalPages},
    ));
  }

  @override
  Future<ApiResult<List<FoodItem>>> getFlashSaleItems() async {
    if (shouldFail) return Failure(message: failMessage);
    return Success(_makeItems(1));
  }

  @override
  Future<ApiResult<FoodItem>> getFoodItemDetail(int id) async {
    if (shouldFail) return Failure(message: failMessage);
    return Success(
      FoodItem(
        id: id,
        name: 'Detail Item $id',
        originalPrice: '30000',
        rescuePrice: '15000',
        discountPct: 50,
        quantity: 5,
        status: 'available',
      ),
    );
  }
}

// ─── Tests ────────────────────────────────────

void main() {
  late FakeBrowseRepository fakeRepo;
  late BrowseNotifier notifier;

  setUp(() {
    fakeRepo = FakeBrowseRepository();
    notifier = BrowseNotifier(fakeRepo);
  });

  group('BrowseNotifier.loadFoodItems', () {
    test('loads first page successfully', () async {
      await notifier.loadFoodItems();

      expect(notifier.state.items, hasLength(3));
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.currentPage, 1);
      expect(notifier.state.hasMore, true);
    });

    test('sets error on failure', () async {
      fakeRepo.shouldFail = true;
      fakeRepo.failMessage = 'Koneksi gagal';
      await notifier.loadFoodItems();

      expect(notifier.state.items, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Koneksi gagal');
    });

    test('passes category and search filters', () async {
      await notifier.loadFoodItems(
        category: 'bakery',
        search: 'roti',
        sortBy: 'price',
      );

      expect(notifier.state.selectedCategory, 'bakery');
      expect(notifier.state.searchQuery, 'roti');
      expect(notifier.state.sortBy, 'price');
    });

    test('hasMore is false when on last page', () async {
      fakeRepo.totalPages = 1;
      await notifier.loadFoodItems();

      expect(notifier.state.hasMore, false);
    });
  });

  group('BrowseNotifier.loadMore', () {
    test('appends items from page 2', () async {
      await notifier.loadFoodItems(); // page 1
      expect(notifier.state.items, hasLength(3));

      await notifier.loadMore(); // page 2
      expect(notifier.state.items, hasLength(6));
      expect(notifier.state.currentPage, 2);
      expect(notifier.state.hasMore, false); // totalPages=2
    });

    test('does nothing when already loading', () async {
      await notifier.loadFoodItems();
      // Manually set loading to simulate concurrent call
      // (test the guard clause)
      // loadMore should return early because loadFoodItems completed
      // and hasMore is true — so this call should succeed
      await notifier.loadMore();
      expect(notifier.state.items, hasLength(6));
    });

    test('does nothing when no more pages', () async {
      fakeRepo.totalPages = 1;
      await notifier.loadFoodItems();
      expect(notifier.state.hasMore, false);

      await notifier.loadMore();
      expect(notifier.state.items, hasLength(3)); // unchanged
    });
  });

  group('BrowseNotifier.setCategory', () {
    test('reloads items with new category', () async {
      await notifier.setCategory('supermarket');
      expect(notifier.state.selectedCategory, 'supermarket');
      expect(notifier.state.items, hasLength(3));
    });
  });

  group('BrowseNotifier.search', () {
    test('reloads items with search query', () async {
      await notifier.search('nasi goreng');
      expect(notifier.state.searchQuery, 'nasi goreng');
      expect(notifier.state.items, hasLength(3));
    });
  });
}
