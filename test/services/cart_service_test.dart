// test/services/cart_service_test.dart
//
// ✅ हा टेस्ट CartService चा request-building आणि response-parsing logic
// तपासतो — खरा network call न करता. ApiClient च्या जागी खोटं (mock)
// ApiClient वापरलंय — त्यामुळे आपण control करू शकतो: "get('/cart') call
// आला की हा raw JSON दे" आणि मग CartService त्याला कसं parse करतं ते
// तपासतो (उदा. comma असलेले amounts, branch-price नसलेले items, इ.).

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/services/cart_service.dart';
import 'package:dcs_app/services/api_client.dart';

// ── खोटं (mock) ApiClient बनवा ──────────────────────────────────────
class MockApiClient extends Mock implements ApiClient {}

// helper: दिलेल्या data सकट एक खोटं dio Response बनवतं
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
    test('comma असलेले amounts (उदा. "6,600.00") बरोबर parse होतात', () async {
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

      // ── Assert: comma काढून बरोबर double मध्ये convert झालं ──────────
      expect(result['total_amount'], 6600.0);
      expect(result['discount'], 1000.0);
      expect(result['final_amount'], 5600.0);
      expect(result['cart_count'], 1);
      expect(result['coupon_code'], 'SAVE1000');
    });

    test('final_amount नसेल तर subtotal fallback म्हणून वापरतो', () async {
      when(() => mockApi.get('/cart')).thenAnswer((_) async => _res({
        'data': {
          'items':    [],
          'count':    0,
          'subtotal': '500.00',
          // final_amount आणि discount दिलेलेच नाहीत
        },
      }));

      final result = await cartService.getCart();

      expect(result['final_amount'], 500.0); // subtotal fallback
      expect(result['discount'], 0.0);
    });
  });

  group('CartService.addToCart', () {
    test('productId "id" key म्हणून पाठवतो, extras merge होतात', () async {
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
      expect(captured.containsKey('product_id'), false); // जुना wrong key नसावा
    });
  });

  group('CartService.updateCartItem', () {
    test('rowId आणि qty बरोबर keys सोबत PUT होतात', () async {
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
    test('rowId सोबत DELETE call होतो', () async {
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
    test('applyCoupon "code" key सोबत बरोबर endpoint ला जातं', () async {
      when(() => mockApi.post('/checkout/apply-coupon', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'status': true}));

      await cartService.applyCoupon('WELCOME100');

      verify(() => mockApi.post(
        '/checkout/apply-coupon',
        data: {'code': 'WELCOME100'},
      )).called(1);
    });

    test('removeCoupon बरोबर endpoint ला रिकाम्या body सोबत जातं', () async {
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
    test('status false असल्यास backend चा message throw होतो', () async {
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
    test('status false असल्यास throw होतो', () async {
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

    test('available/unavailable items बरोबर वेगळे parse होतात', () async {
      when(() => mockApi.post('/cart/set-branch', data: any(named: 'data')))
          .thenAnswer((_) async => _res({
        'data': {
          'branch_id': 5,
          'prices': {
            'r1': {'price_per_unit': '100.00', 'final_price': '250.50', 'sqft': 10},
            'r2': null, // ✅ या branch मध्ये उपलब्ध नाही
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