// test/services/order_service_test.dart
//
// ✅ हा टेस्ट OrderService चा request-building logic तपासतो — खरा network
// call न करता. ApiClient mock केलाय. सगळ्यात महत्त्वाचं: processOrder /
// processAdvanceOrder मध्ये 403 (DPDPA pending deletion) आल्यास ते
// AccountDeletionPendingException मध्ये बरोबर convert होतं का, हे इथे
// तपासलंय.

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/services/order_service.dart';
import 'package:dcs_app/services/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}

Response _res(dynamic data, {int statusCode = 200}) => Response(
  requestOptions: RequestOptions(path: ''),
  data:           data,
  statusCode:     statusCode,
);

// processOrder/processAdvanceOrder साठी सामायिक arguments — प्रत्येक
// टेस्टमध्ये पुन्हा पुन्हा लिहिण्याऐवजी इथे एकदाच.
Future<Map<String, dynamic>> _callProcessOrder(
    OrderService service, {
      String? apartment,
      String? orderNotes,
    }) {
  return service.processOrder(
    firstName:   'Rahul',
    lastName:    'Sharma',
    email:       'rahul@test.com',
    branchId:    1,
    country:     10,
    apartment:   apartment,
    address:     '123 Main St',
    city:        'Pune',
    zip:         '411001',
    mobile:      '9999999999',
    bookingDate: '2026-08-01',
    bookingTime: '10:00 AM',
    orderNotes:  orderNotes,
  );
}

void main() {
  late MockApiClient mockApi;
  late OrderService orderService;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApi = MockApiClient();
    orderService = OrderService(apiClient: mockApi);
  });

  group('OrderService.getOrders', () {
    test('status दिलेला नसेल तर queryParams मध्ये status key जातच नाही', () async {
      when(() => mockApi.get('/orders', queryParams: any(named: 'queryParams')))
          .thenAnswer((_) async => _res({'data': {'orders': []}}));

      await orderService.getOrders();

      final captured = verify(() => mockApi.get(
        '/orders',
        queryParams: captureAny(named: 'queryParams'),
      )).captured.single as Map;

      expect(captured.containsKey('status'), false);
      expect(captured['page'], 1);
    });

    test('status दिलेला असेल तर तो queryParams मध्ये जातो', () async {
      when(() => mockApi.get('/orders', queryParams: any(named: 'queryParams')))
          .thenAnswer((_) async => _res({'data': {'orders': []}}));

      await orderService.getOrders(status: 'completed', page: 2);

      final captured = verify(() => mockApi.get(
        '/orders',
        queryParams: captureAny(named: 'queryParams'),
      )).captured.single as Map;

      expect(captured['status'], 'completed');
      expect(captured['page'], 2);
    });
  });

  group('OrderService.checkoutInit', () {
    test('branch_id queryParam म्हणून पाठवतो', () async {
      when(() => mockApi.get('/checkout/init', queryParams: any(named: 'queryParams')))
          .thenAnswer((_) async => _res({'data': {}}));

      await orderService.checkoutInit(branchId: 7);

      verify(() => mockApi.get(
        '/checkout/init',
        queryParams: {'branch_id': 7},
      )).called(1);
    });
  });

  group('OrderService.applyCoupon / removeCoupon', () {
    test('countryId दिलेला असेल तरच country_id body मध्ये जातो', () async {
      when(() => mockApi.post('/checkout/apply-coupon', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'data': {}}));

      await orderService.applyCoupon(code: 'SAVE10', countryId: 5);

      final captured = verify(() => mockApi.post(
        '/checkout/apply-coupon',
        data: captureAny(named: 'data'),
      )).captured.single as Map;

      expect(captured['code'], 'SAVE10');
      expect(captured['country_id'], 5);
    });

    test('countryId null असेल तर country_id key body मध्ये जातच नाही', () async {
      when(() => mockApi.post('/checkout/remove-coupon', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'data': {}}));

      await orderService.removeCoupon();

      final captured = verify(() => mockApi.post(
        '/checkout/remove-coupon',
        data: captureAny(named: 'data'),
      )).captured.single as Map;

      expect(captured.containsKey('country_id'), false);
    });
  });

  group('OrderService.processOrder', () {
    test('रिकाम्या apartment/orderNotes body मध्ये पाठवले जात नाहीत', () async {
      when(() => mockApi.post('/checkout/process', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'data': {'id': 1}}));

      await _callProcessOrder(orderService, apartment: '', orderNotes: '');

      final captured = verify(() => mockApi.post(
        '/checkout/process',
        data: captureAny(named: 'data'),
      )).captured.single as Map;

      expect(captured.containsKey('apartment'), false);
      expect(captured.containsKey('order_notes'), false);
      expect(captured['branch_id'], 1);
    });

    test('apartment/orderNotes दिलेले असतील तर body मध्ये जातात', () async {
      when(() => mockApi.post('/checkout/process', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'data': {'id': 1}}));

      await _callProcessOrder(orderService, apartment: 'Flat 4B', orderNotes: 'Ring bell twice');

      final captured = verify(() => mockApi.post(
        '/checkout/process',
        data: captureAny(named: 'data'),
      )).captured.single as Map;

      expect(captured['apartment'], 'Flat 4B');
      expect(captured['order_notes'], 'Ring bell twice');
    });

    test('403 आल्यास AccountDeletionPendingException मध्ये convert होतो', () async {
      when(() => mockApi.post('/checkout/process', data: any(named: 'data')))
          .thenThrow(ApiException('Account pending deletion.', statusCode: 403));

      expect(
            () => _callProcessOrder(orderService),
        throwsA(isA<AccountDeletionPendingException>()),
      );
    });

    test('403 शिवाय दुसरा error असल्यास तसाच rethrow होतो (convert होत नाही)', () async {
      when(() => mockApi.post('/checkout/process', data: any(named: 'data')))
          .thenThrow(ApiException('Server error.', statusCode: 500));

      expect(
            () => _callProcessOrder(orderService),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('OrderService.processAdvanceOrder', () {
    test('403 आल्यास इथेही AccountDeletionPendingException मध्ये convert होतो', () async {
      when(() => mockApi.post('/checkout/process-advance', data: any(named: 'data')))
          .thenThrow(ApiException('Account pending deletion.', statusCode: 403));

      expect(
            () => orderService.processAdvanceOrder(
          firstName:   'Rahul',
          lastName:    'Sharma',
          email:       'rahul@test.com',
          branchId:    1,
          country:     10,
          address:     '123 Main St',
          city:        'Pune',
          zip:         '411001',
          mobile:      '9999999999',
          bookingDate: '2026-08-01',
          bookingTime: '10:00 AM',
        ),
        throwsA(isA<AccountDeletionPendingException>()),
      );
    });
  });
}