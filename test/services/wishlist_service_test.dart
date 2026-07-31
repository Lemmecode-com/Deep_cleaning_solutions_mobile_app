// test/services/wishlist_service_test.dart

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/services/api_client.dart';
import 'package:dcs_app/services/wishlist_service.dart';

class MockApiClient extends Mock implements ApiClient {}

Response<T> _fakeResponse<T>(T data, {String path = '/wishlist'}) {
  return Response<T>(
    data: data,
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
  );
}

void main() {
  late MockApiClient mockApiClient;
  late WishlistService wishlistService;

  setUp(() {
    mockApiClient = MockApiClient();
    wishlistService = WishlistService(apiClient: mockApiClient);
  });

  group('getWishlist', () {
    test('extracts items + count from the data wrapper', () async {
      when(() => mockApiClient.get('/wishlist')).thenAnswer(
            (_) async => _fakeResponse({
          'data': {
            'items': [
              {'id': 1},
              {'id': 2},
            ],
            'count': 2,
          },
        }),
      );

      final result = await wishlistService.getWishlist();

      expect(result['items'], [
        {'id': 1},
        {'id': 2},
      ]);
      expect(result['count'], 2);
    });

    test('gives empty items / 0 count when data is missing', () async {
      when(() => mockApiClient.get('/wishlist'))
          .thenAnswer((_) async => _fakeResponse({}));

      final result = await wishlistService.getWishlist();

      expect(result['items'], []);
      expect(result['count'], 0);
    });
  });

  group('addToWishlist', () {
    test('does a POST with product_id and returns response.data', () async {
      when(() => mockApiClient.post('/wishlist', data: {'product_id': 5}))
          .thenAnswer((_) async => _fakeResponse({'status': true}));

      final result = await wishlistService.addToWishlist(5);

      expect(result['status'], true);
      verify(() => mockApiClient.post('/wishlist', data: {'product_id': 5}))
          .called(1);
    });
  });

  group('removeFromWishlist', () {
    test('does a DELETE with product_id and returns response.data', () async {
      when(() => mockApiClient.delete('/wishlist', data: {'product_id': 5}))
          .thenAnswer((_) async => _fakeResponse({'status': true}));

      final result = await wishlistService.removeFromWishlist(5);

      expect(result['status'], true);
      verify(() => mockApiClient.delete('/wishlist', data: {'product_id': 5}))
          .called(1);
    });
  });

  group('checkWishlistStatus', () {
    test('does a POST with product_id and returns response.data', () async {
      when(() => mockApiClient.post(
        '/wishlist/check-status',
        data: {'product_id': 5},
      )).thenAnswer((_) async => _fakeResponse({'in_wishlist': true}));

      final result = await wishlistService.checkWishlistStatus(5);

      expect(result['in_wishlist'], true);
    });
  });

  group('getWishlistCount', () {
    test('extracts count from the data wrapper', () async {
      when(() => mockApiClient.get('/wishlist/count')).thenAnswer(
            (_) async => _fakeResponse({
          'data': {'count': 7},
        }),
      );

      final count = await wishlistService.getWishlistCount();

      expect(count, 7);
    });

    test('gives 0 when data is missing', () async {
      when(() => mockApiClient.get('/wishlist/count'))
          .thenAnswer((_) async => _fakeResponse({}));

      final count = await wishlistService.getWishlistCount();

      expect(count, 0);
    });
  });
}
