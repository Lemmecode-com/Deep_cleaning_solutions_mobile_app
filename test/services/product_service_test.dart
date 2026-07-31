// test/services/product_service_test.dart
//
// ✅ This test checks ProductService's request-building and, most
// importantly, the shared `_unwrap()` response-parsing logic. Most
// methods (getProducts, getProductDetail, etc.) go through this same
// helper, so three shapes are specifically checked: `data.data` being a
// Map, being a List, or the `data` key being absent — whether each
// dispatches correctly.

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/services/product_service.dart';
import 'package:dcs_app/services/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}

Response _res(dynamic data, {int statusCode = 200}) => Response(
  requestOptions: RequestOptions(path: ''),
  data:           data,
  statusCode:     statusCode,
);

void main() {
  late MockApiClient mockApi;
  late ProductService productService;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApi = MockApiClient();
    productService = ProductService(apiClient: mockApi);
  });

  group('ProductService — _unwrap shared parsing', () {
    test('gets wrapped into a {"products": [...]} shape when data.data is a List', () async {
      when(() => mockApi.get('/products', queryParams: any(named: 'queryParams')))
          .thenAnswer((_) async => _res({
        'data': [
          {'id': 1, 'name': 'Deep Cleaning'},
          {'id': 2, 'name': 'Sofa Cleaning'},
        ],
      }));

      final result = await productService.getProducts();

      expect(result['products'], isA<List>());
      expect(result['products'].length, 2);
    });

    test('the inner map is returned as-is when data.data is a Map', () async {
      when(() => mockApi.get('/products/5')).thenAnswer((_) async => _res({
        'data': {
          'product': {'id': 5, 'name': 'AC Service'},
        },
      }));

      final result = await productService.getProductDetail(5);

      expect(result['product']['name'], 'AC Service');
    });

    test('the entire top-level map is returned as-is when there is no "data" key', () async {
      when(() => mockApi.get('/products/furnished-flats'))
          .thenAnswer((_) async => _res({
        'status':   true,
        'products': [{'id': 1}],
      }));

      final result = await productService.getFurnishedFlats();

      expect(result['status'], true);
      expect(result['products'], isA<List>());
    });

    test('returns an empty map without crashing when the response is not a Map (null/garbage)', () async {
      when(() => mockApi.get('/products/unfurnished-flats'))
          .thenAnswer((_) async => _res(null));

      final result = await productService.getUnfurnishedFlats();

      expect(result, <String, dynamic>{});
    });
  });

  group('ProductService.getProducts — query params', () {
    test('the category/search keys are not sent in queryParams when they are not given', () async {
      when(() => mockApi.get('/products', queryParams: any(named: 'queryParams')))
          .thenAnswer((_) async => _res({'data': <dynamic>[]}));

      await productService.getProducts();

      final captured = verify(() => mockApi.get(
        '/products',
        queryParams: captureAny(named: 'queryParams'),
      )).captured.single as Map;

      expect(captured.containsKey('category'), false);
      expect(captured.containsKey('search'), false);
      expect(captured['page'], 1);
    });

    test('category/search go into queryParams when they are given', () async {
      when(() => mockApi.get('/products', queryParams: any(named: 'queryParams')))
          .thenAnswer((_) async => _res({'data': <dynamic>[]}));

      await productService.getProducts(category: 'cleaning', search: 'sofa', page: 2);

      final captured = verify(() => mockApi.get(
        '/products',
        queryParams: captureAny(named: 'queryParams'),
      )).captured.single as Map;

      expect(captured['category'], 'cleaning');
      expect(captured['search'], 'sofa');
      expect(captured['page'], 2);
    });
  });

  group('ProductService.searchProducts', () {
    test('the query is sent with the "keyword" key, not "q" (old bug)', () async {
      when(() => mockApi.get('/products/search', queryParams: any(named: 'queryParams')))
          .thenAnswer((_) async => _res({'data': <dynamic>[]}));

      await productService.searchProducts('sofa cleaning');

      final captured = verify(() => mockApi.get(
        '/products/search',
        queryParams: captureAny(named: 'queryParams'),
      )).captured.single as Map;

      expect(captured['keyword'], 'sofa cleaning');
      expect(captured.containsKey('q'), false);
    });
  });

  group('ProductService.getBHKList', () {
    test('both type and bhk go into queryParams', () async {
      when(() => mockApi.get('/products/bhk-list', queryParams: any(named: 'queryParams')))
          .thenAnswer((_) async => _res({'data': <dynamic>[]}));

      await productService.getBHKList(type: 'furnished', bhk: '2BHK');

      verify(() => mockApi.get(
        '/products/bhk-list',
        queryParams: {'type': 'furnished', 'bhk': '2BHK'},
      )).called(1);
    });
  });

  group('ProductService.addProductReview', () {
    test('POSTs to the correct endpoint with the correct rating and review payload', () async {
      when(() => mockApi.post('/products/9/reviews', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'data': {'id': 1}}));

      await productService.addProductReview(
        productId: 9,
        rating: 5,
        review: 'Excellent service!',
      );

      verify(() => mockApi.post(
        '/products/9/reviews',
        data: {'rating': 5, 'review': 'Excellent service!'},
      )).called(1);
    });
  });
}
