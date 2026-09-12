// test/services/order_service_test.dart
//
// ✅ This test checks OrderService's request-building logic — without
// making a real network call. ApiClient is mocked. Most importantly: it
// checks that a 403 (DPDPA pending deletion) in processOrder /
// processAdvanceOrder gets correctly converted into an
// AccountDeletionPendingException.

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

// Shared arguments for processOrder/processAdvanceOrder — kept here once
// instead of rewriting them in every single test.
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
    test('the status key is not sent in queryParams when status is not given', () async {
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

    test('status goes into queryParams when it is given', () async {
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
    test('sends branch_id as a queryParam', () async {
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
    test('country_id goes into the body only when countryId is given', () async {
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

    test('the country_id key is not sent in the body when countryId is null', () async {
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
    test('empty apartment/orderNotes are not sent in the body', () async {
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

    test('apartment/orderNotes go into the body when they are given', () async {
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

    test('a 403 gets converted into an AccountDeletionPendingException', () async {
      when(() => mockApi.post('/checkout/process', data: any(named: 'data')))
          .thenThrow(ApiException('Account pending deletion.', statusCode: 403));

      expect(
            () => _callProcessOrder(orderService),
        throwsA(isA<AccountDeletionPendingException>()),
      );
    });

    test('any other error besides 403 is rethrown unchanged (not converted)', () async {
      when(() => mockApi.post('/checkout/process', data: any(named: 'data')))
          .thenThrow(ApiException('Server error.', statusCode: 500));

      expect(
            () => _callProcessOrder(orderService),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('OrderService.processAdvanceOrder', () {
    test('a 403 gets converted into an AccountDeletionPendingException here too', () async {
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
