// test/providers/product_notifier_test.dart
//
// ✅ This test checks ProductNotifier's state-management logic — without
// making a real API call. ProductService is mocked.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/providers/product_provider.dart';
import 'package:dcs_app/services/product_service.dart';

class MockProductService extends Mock implements ProductService {}

void main() {
  late MockProductService mockProductService;
  late ProviderContainer container;

  setUp(() {
    mockProductService = MockProductService();

    container = ProviderContainer(
      overrides: [
        productProvider.overrideWith(
              (ref) => ProductNotifier(productService: mockProductService),
        ),
      ],
    );

    addTearDown(container.dispose);
  });

  group('ProductNotifier.getProducts', () {
    test('fills products into state on success', () async {
      when(() => mockProductService.getProducts(
        category: any(named: 'category'),
        search:   any(named: 'search'),
        page:     any(named: 'page'),
      )).thenAnswer((_) async => {
        'products': [
          {'id': 1, 'name': 'Deep Cleaning'},
          {'id': 2, 'name': 'Sofa Cleaning'},
        ],
      });

      final notifier = container.read(productProvider.notifier);
      await notifier.getProducts();

      final state = container.read(productProvider);
      expect(state.isLoading, false);
      expect(state.products.length, 2);
      expect(state.error, null);
    });

    test('sets error state and keeps products empty on failure', () async {
      when(() => mockProductService.getProducts(
        category: any(named: 'category'),
        search:   any(named: 'search'),
        page:     any(named: 'page'),
      )).thenThrow(Exception('Network error'));

      final notifier = container.read(productProvider.notifier);
      await notifier.getProducts();

      final state = container.read(productProvider);
      expect(state.isLoading, false);
      expect(state.error, contains('Network error'));
      expect(state.products, isEmpty);
    });
  });

  group('ProductNotifier.getProductDetail', () {
    test('sets selectedProduct in state on success', () async {
      when(() => mockProductService.getProductDetail(any()))
          .thenAnswer((_) async => {
        'product': {'id': 5, 'name': 'AC Service', 'price': 999},
      });

      final notifier = container.read(productProvider.notifier);
      await notifier.getProductDetail(5);

      final state = container.read(productProvider);
      expect(state.selectedProduct?['name'], 'AC Service');
      expect(state.error, null);
    });
  });

  group('ProductNotifier.getFurnishedFlats / getUnfurnishedFlats', () {
    test('furnished flats get saved into a separate list', () async {
      when(() => mockProductService.getFurnishedFlats())
          .thenAnswer((_) async => {
        'products': [{'id': 1, 'name': '2BHK Furnished'}],
      });

      final notifier = container.read(productProvider.notifier);
      await notifier.getFurnishedFlats();

      final state = container.read(productProvider);
      expect(state.furnishedFlats.length, 1);
      expect(state.unfurnishedFlats, isEmpty); // ✅ the other list wasn't touched
    });

    test('unfurnished flats get saved into a separate list', () async {
      when(() => mockProductService.getUnfurnishedFlats())
          .thenAnswer((_) async => {
        'products': [{'id': 2, 'name': '3BHK Unfurnished'}],
      });

      final notifier = container.read(productProvider.notifier);
      await notifier.getUnfurnishedFlats();

      final state = container.read(productProvider);
      expect(state.unfurnishedFlats.length, 1);
      expect(state.furnishedFlats, isEmpty);
    });
  });

  group('ProductNotifier.searchProducts', () {
    test('search results go into a separate "searchResults" state field', () async {
      when(() => mockProductService.searchProducts(any()))
          .thenAnswer((_) async => {
        'products': [{'id': 3, 'name': 'Sofa Cleaning'}],
      });

      final notifier = container.read(productProvider.notifier);
      await notifier.searchProducts('sofa');

      final state = container.read(productProvider);
      expect(state.searchResults.length, 1);
      expect(state.products, isEmpty); // ✅ the main products list wasn't touched
    });
  });

  group('ProductNotifier.getProductReviews / addProductReview', () {
    test('reviews land in state when getProductReviews succeeds', () async {
      when(() => mockProductService.getProductReviews(any()))
          .thenAnswer((_) async => {
        'reviews': [
          {'id': 1, 'rating': 5, 'review': 'Great!'},
        ],
      });

      final notifier = container.read(productProvider.notifier);
      await notifier.getProductReviews(9);

      final state = container.read(productProvider);
      expect(state.reviews.length, 1);
    });

    test('addProductReview returns true on success and refreshes reviews', () async {
      when(() => mockProductService.addProductReview(
        productId: any(named: 'productId'),
        rating:    any(named: 'rating'),
        review:    any(named: 'review'),
      )).thenAnswer((_) async => {'status': true});

      when(() => mockProductService.getProductReviews(any()))
          .thenAnswer((_) async => {
        'reviews': [
          {'id': 2, 'rating': 4, 'review': 'Good service'},
        ],
      });

      final notifier = container.read(productProvider.notifier);
      final result = await notifier.addProductReview(
        productId: 9,
        rating: 4,
        review: 'Good service',
      );

      final state = container.read(productProvider);
      expect(result, true);
      expect(state.reviews.length, 1);
      verify(() => mockProductService.getProductReviews(9)).called(1);
    });

    test('addProductReview returns false and sets error state on failure', () async {
      when(() => mockProductService.addProductReview(
        productId: any(named: 'productId'),
        rating:    any(named: 'rating'),
        review:    any(named: 'review'),
      )).thenThrow(Exception('Review already submitted'));

      final notifier = container.read(productProvider.notifier);
      final result = await notifier.addProductReview(
        productId: 9,
        rating: 1,
        review: 'test',
      );

      final state = container.read(productProvider);
      expect(result, false);
      expect(state.error, contains('Review already submitted'));
    });
  });

  group('ProductNotifier — clear helpers', () {
    test('selectedProduct becomes null after clearSelectedProduct', () async {
      when(() => mockProductService.getProductDetail(any()))
          .thenAnswer((_) async => {'product': {'id': 1}});

      final notifier = container.read(productProvider.notifier);
      await notifier.getProductDetail(1);
      expect(container.read(productProvider).selectedProduct, isNotNull);

      notifier.clearSelectedProduct();
      expect(container.read(productProvider).selectedProduct, null);
    });
  });
}
