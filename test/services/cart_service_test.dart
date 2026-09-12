// test/services/cart_service_test.dart
//
// ✅ This test checks CartService's request-building and response-parsing
// logic — without making a real network call. A fake (mock) ApiClient is
// used in place of ApiClient — so we can control it: "when the
// get('/cart') call comes, give this raw JSON" and then check how
// CartService parses it (e.g. amounts with commas, items with no
// branch-price, etc.).

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/services/cart_service.dart';
import 'package:dcs_app/services/api_client.dart';

// ── Create a fake (mock) ApiClient ──────────────────────────────────
class MockApiClient extends Mock implements ApiClient {}

// helper: builds a fake dio Response with the given data
Response _res(dynamic data, {int statusCode = 200}) => Response(
  requestOptions: RequestOptions(path: ''),
  data:           data,
  statusCode:     statusCode,
);

void main() {
  late MockApiClient mockApi;
  late CartService cartService;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApi = MockApiClient();
    cartService = CartService(apiClient: mockApi);
  });

  group('CartService.getCart', () {
    test('amounts with commas (e.g. "6,600.00") get parsed correctly', () async {
      // ── Arrange ──────────────────────────────────────────────────
      when(() => mockApi.get('/cart')).thenAnswer((_) async => _res({
        'data': {
          'items':       [{'rowId': 'r1'}],
          'count':       1,
          'subtotal':    '6,600.00',
          'discount':    '1,000.00',
          'final_amount': '5,600.00',
          'coupon_code': 'SAVE1000',
        },
      }));

      // ── Act ──────────────────────────────────────────────────────
      final result = await cartService.getCart();

      // ── Assert: commas removed and correctly converted into a double ──────────
      expect(result['total_amount'], 6600.0);
      expect(result['discount'], 1000.0);
      expect(result['final_amount'], 5600.0);
      expect(result['cart_count'], 1);
      expect(result['coupon_code'], 'SAVE1000');
    });

    test('uses subtotal as a fallback when final_amount is missing', () async {
      when(() => mockApi.get('/cart')).thenAnswer((_) async => _res({
        'data': {
          'items':    [],
          'count':    0,
          'subtotal': '500.00',
          // final_amount and discount aren't given at all
        },
      }));

      final result = await cartService.getCart();

      expect(result['final_amount'], 500.0); // subtotal fallback
      expect(result['discount'], 0.0);
    });
  });

  group('CartService.addToCart', () {
    test('sends productId as the "id" key, extras get merged in', () async {
      when(() => mockApi.post('/cart/add', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'status': true}));

      await cartService.addToCart(
        productId: 42,
        extras: {'note': 'no soap'},
      );

      final captured = verify(() => mockApi.post(
        '/cart/add',
        data: captureAny(named: 'data'),
      )).captured.single as Map;

      expect(captured['id'], 42);
      expect(captured['note'], 'no soap');
      expect(captured.containsKey('product_id'), false); // the old wrong key shouldn't be present
    });
  });

  group('CartService.updateCartItem', () {
    test('PUTs with the correct rowId and qty keys', () async {
      when(() => mockApi.put('/cart/update', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'status': true}));

      await cartService.updateCartItem(rowId: 'r7', qty: 3);

      final captured = verify(() => mockApi.put(
        '/cart/update',
        data: captureAny(named: 'data'),
      )).captured.single as Map;

      expect(captured['rowId'], 'r7');
      expect(captured['qty'], 3);
    });
  });

  group('CartService.removeCartItem', () {
    test('DELETE call is made with the rowId', () async {
      when(() => mockApi.delete('/cart/item', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'status': true}));

      await cartService.removeCartItem('r9');

      verify(() => mockApi.delete(
        '/cart/item',
        data: {'rowId': 'r9'},
      )).called(1);
    });
  });

  group('CartService.applyCoupon / removeCoupon', () {
    test('applyCoupon hits the correct endpoint with the "code" key', () async {
      when(() => mockApi.post('/checkout/apply-coupon', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'status': true}));

      await cartService.applyCoupon('WELCOME100');

      verify(() => mockApi.post(
        '/checkout/apply-coupon',
        data: {'code': 'WELCOME100'},
      )).called(1);
    });

    test('removeCoupon hits the correct endpoint with an empty body', () async {
      when(() => mockApi.post('/checkout/remove-coupon', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'status': true}));

      await cartService.removeCoupon();

      verify(() => mockApi.post(
        '/checkout/remove-coupon',
        data: <String, dynamic>{},
      )).called(1);
    });
  });

  group('CartService.addFlatToCart', () {
    test('throws the backend\'s message when status is false', () async {
      when(() => mockApi.post('/cart/add-flat', data: any(named: 'data')))
          .thenAnswer((_) async => _res({
        'status':  false,
        'message': 'Sqft cannot be zero.',
      }));

      expect(
            () => cartService.addFlatToCart(
          mainProductId: 1,
          sqft: 0,
          addons: [],
        ),
        throwsA('Sqft cannot be zero.'),
      );
    });
  });

  group('CartService.setBranch', () {
    test('throws when status is false', () async {
      when(() => mockApi.post('/cart/set-branch', data: any(named: 'data')))
          .thenAnswer((_) async => _res({
        'status':  false,
        'message': 'Branch not serviceable.',
      }));

      expect(
            () => cartService.setBranch(5),
        throwsA('Branch not serviceable.'),
      );
    });

    test('available/unavailable items are parsed separately and correctly', () async {
      when(() => mockApi.post('/cart/set-branch', data: any(named: 'data')))
          .thenAnswer((_) async => _res({
        'data': {
          'branch_id': 5,
          'prices': {
            'r1': {'price_per_unit': '100.00', 'final_price': '250.50', 'sqft': 10},
            'r2': null, // ✅ not available at this branch
          },
          'unavailable': [
            {'rowId': 'r2', 'name': 'Deep Cleaning'},
          ],
          'subtotal': '1,000.00',
        },
      }));

      final result = await cartService.setBranch(5);

      expect(result['branch_id'], 5);
      expect(result['prices']['r1']['available'], true);
      expect(result['prices']['r1']['final_price'], 250.5);
      expect(result['prices']['r2']['available'], false);
      expect(result['unavailable'], [
        {'rowId': 'r2', 'name': 'Deep Cleaning'},
      ]);
      expect(result['subtotal'], 1000.0);
    });
  });
}
