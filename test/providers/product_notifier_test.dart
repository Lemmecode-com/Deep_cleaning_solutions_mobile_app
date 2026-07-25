// test/providers/product_notifier_test.dart
//
// ✅ हा टेस्ट ProductNotifier चा state-management logic तपासतो — खरा API
// call न करता. ProductService mock केलाय.

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
    test('यशस्वी झाल्यास products state मध्ये भरतात', () async {
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

    test('fail झाल्यास error state सेट होते, products रिकामीच राहते', () async {
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
    test('यशस्वी झाल्यास selectedProduct state मध्ये सेट होतो', () async {
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
    test('furnished flats वेगळ्या list मध्ये save होतात', () async {
      when(() => mockProductService.getFurnishedFlats())
          .thenAnswer((_) async => {
        'products': [{'id': 1, 'name': '2BHK Furnished'}],
      });

      final notifier = container.read(productProvider.notifier);
      await notifier.getFurnishedFlats();

      final state = container.read(productProvider);
      expect(state.furnishedFlats.length, 1);
      expect(state.unfurnishedFlats, isEmpty); // ✅ दुसरी list touch झाली नाही
    });

    test('unfurnished flats वेगळ्या list मध्ये save होतात', () async {
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
    test('search results वेगळ्या "searchResults" state field मध्ये जातात', () async {
      when(() => mockProductService.searchProducts(any()))
          .thenAnswer((_) async => {
        'products': [{'id': 3, 'name': 'Sofa Cleaning'}],
      });

      final notifier = container.read(productProvider.notifier);
      await notifier.searchProducts('sofa');

      final state = container.read(productProvider);
      expect(state.searchResults.length, 1);
      expect(state.products, isEmpty); // ✅ मुख्य products list touch झाली नाही
    });
  });

  group('ProductNotifier.getProductReviews / addProductReview', () {
    test('getProductReviews यशस्वी झाल्यास reviews state मध्ये येतात', () async {
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

    test('addProductReview यशस्वी झाल्यास true return करतो आणि reviews refresh करतो', () async {
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

    test('addProductReview fail झाल्यास false return करतो आणि error state सेट होते', () async {
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
    test('clearSelectedProduct केल्यावर selectedProduct null होतो', () async {
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