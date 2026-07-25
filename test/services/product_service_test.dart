// test/services/product_service_test.dart
//
// ✅ हा टेस्ट ProductService चा request-building आणि सगळ्यात महत्त्वाचं —
// शेअर्ड `_unwrap()` response-parsing logic तपासतो. बहुतेक सगळे methods
// (getProducts, getProductDetail, इ.) याच helper मधून जातात, त्यामुळे तीन
// आकार खास तपासलेत: `data.data` हा Map असेल, List असेल, किंवा `data` key
// नसेल — प्रत्येक वेगळा dispatch होतो का ते.

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
    test('data.data List असेल तर {"products": [...]} अशा shape मध्ये wrap होतो', () async {
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

    test('data.data Map असेल तर तो inner map जसाच्या तसा return होतो', () async {
      when(() => mockApi.get('/products/5')).thenAnswer((_) async => _res({
        'data': {
          'product': {'id': 5, 'name': 'AC Service'},
        },
      }));

      final result = await productService.getProductDetail(5);

      expect(result['product']['name'], 'AC Service');
    });

    test('"data" key नसेल तर पूर्ण top-level map जसाच्या तसा return होतो', () async {
      when(() => mockApi.get('/products/furnished-flats'))
          .thenAnswer((_) async => _res({
        'status':   true,
        'products': [{'id': 1}],
      }));

      final result = await productService.getFurnishedFlats();

      expect(result['status'], true);
      expect(result['products'], isA<List>());
    });

    test('response Map नसेल (null/garbage) तर रिकामा map return होतो, crash होत नाही', () async {
      when(() => mockApi.get('/products/unfurnished-flats'))
          .thenAnswer((_) async => _res(null));

      final result = await productService.getUnfurnishedFlats();

      expect(result, <String, dynamic>{});
    });
  });

  group('ProductService.getProducts — query params', () {
    test('category/search दिलेले नसतील तर queryParams मध्ये त्यांचे keys जातच नाहीत', () async {
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

    test('category/search दिलेले असतील तर queryParams मध्ये जातात', () async {
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
    test('query "keyword" key ने पाठवला जातो, "q" ने नाही (जुनी चूक)', () async {
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
    test('type आणि bhk दोन्ही queryParams मध्ये जातात', () async {
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
    test('rating आणि review बरोबर payload सोबत बरोबर endpoint ला POST होतं', () async {
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