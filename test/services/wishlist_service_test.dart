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
    test('data wrapper मधून items + count काढतो', () async {
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

    test('data missing असेल तर empty items / 0 count देतो', () async {
      when(() => mockApiClient.get('/wishlist'))
          .thenAnswer((_) async => _fakeResponse({}));

      final result = await wishlistService.getWishlist();

      expect(result['items'], []);
      expect(result['count'], 0);
    });
  });

  group('addToWishlist', () {
    test('product_id सोबत POST करतो आणि response.data return करतो', () async {
      when(() => mockApiClient.post('/wishlist', data: {'product_id': 5}))
          .thenAnswer((_) async => _fakeResponse({'status': true}));

      final result = await wishlistService.addToWishlist(5);

      expect(result['status'], true);
      verify(() => mockApiClient.post('/wishlist', data: {'product_id': 5}))
          .called(1);
    });
  });

  group('removeFromWishlist', () {
    test('product_id सोबत DELETE करतो आणि response.data return करतो', () async {
      when(() => mockApiClient.delete('/wishlist', data: {'product_id': 5}))
          .thenAnswer((_) async => _fakeResponse({'status': true}));

      final result = await wishlistService.removeFromWishlist(5);

      expect(result['status'], true);
      verify(() => mockApiClient.delete('/wishlist', data: {'product_id': 5}))
          .called(1);
    });
  });

  group('checkWishlistStatus', () {
    test('product_id सोबत POST करतो आणि response.data return करतो', () async {
      when(() => mockApiClient.post(
        '/wishlist/check-status',
        data: {'product_id': 5},
      )).thenAnswer((_) async => _fakeResponse({'in_wishlist': true}));

      final result = await wishlistService.checkWishlistStatus(5);

      expect(result['in_wishlist'], true);
    });
  });

  group('getWishlistCount', () {
    test('data wrapper मधून count काढतो', () async {
      when(() => mockApiClient.get('/wishlist/count')).thenAnswer(
            (_) async => _fakeResponse({
          'data': {'count': 7},
        }),
      );

      final count = await wishlistService.getWishlistCount();

      expect(count, 7);
    });

    test('data missing असेल तर 0 देतो', () async {
      when(() => mockApiClient.get('/wishlist/count'))
          .thenAnswer((_) async => _fakeResponse({}));

      final count = await wishlistService.getWishlistCount();

      expect(count, 0);
    });
  });
}