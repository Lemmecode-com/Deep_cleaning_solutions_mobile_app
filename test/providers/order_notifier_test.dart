// test/providers/order_notifier_test.dart
//
// ✅ हा टेस्ट OrderNotifier चा checkout/orders logic तपासतो — खरा API call
// न करता. OrderService mock केलाय. सगळ्यात महत्त्वाचा टेस्ट: branch पटकन
// बदलल्यास जुना (stale) /checkout/init response नवीन response ला
// override करत नाही, हे "race condition guard" इथे specifically तपासलंय.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/providers/order_provider.dart';
import 'package:dcs_app/services/order_service.dart';

class MockOrderService extends Mock implements OrderService {}

void main() {
  late MockOrderService mockOrderService;
  late ProviderContainer container;

  setUp(() {
    mockOrderService = MockOrderService();

    container = ProviderContainer(
      overrides: [
        orderProvider.overrideWith(
              (ref) => OrderNotifier(orderService: mockOrderService),
        ),
      ],
    );

    addTearDown(container.dispose);
  });

  group('OrderNotifier.getOrders', () {
    test('getOrders यशस्वी झाल्यास orders list state मध्ये भरते', () async {
      when(() => mockOrderService.getOrders(
        status: any(named: 'status'),
        page:   any(named: 'page'),
      )).thenAnswer((_) async => {
        'data': {
          'orders': [
            {'id': 1, 'status': 'completed'},
            {'id': 2, 'status': 'pending'},
          ],
        },
      });

      final notifier = container.read(orderProvider.notifier);
      await notifier.getOrders();

      final state = container.read(orderProvider);
      expect(state.isLoading, false);
      expect(state.orders.length, 2);
      expect(state.error, null);
    });

    test('getOrders fail झाल्यास error state सेट होते', () async {
      when(() => mockOrderService.getOrders(
        status: any(named: 'status'),
        page:   any(named: 'page'),
      )).thenThrow(Exception('Network error'));

      final notifier = container.read(orderProvider.notifier);
      await notifier.getOrders();

      final state = container.read(orderProvider);
      expect(state.isLoading, false);
      expect(state.error, contains('Network error'));
      expect(state.orders, isEmpty);
    });
  });

  group('OrderNotifier.getCheckoutInit — race condition guard', () {
    test('जुना (stale) response उशिरा आला तरी नवीन branch चीच state राहते', () async {
      // ── Arrange ──────────────────────────────────────────────────
      // Branch 1 चा call मुद्दाम "अडकवून" ठेवतोय (Completer वापरून) —
      // जणू काही ती network request अजून चालू आहे.
      final branch1Completer = Completer<Map<String, dynamic>>();
      when(() => mockOrderService.checkoutInit(branchId: 1))
          .thenAnswer((_) => branch1Completer.future);

      // Branch 2 चा call लगेच (synchronously-ish) resolve होतो.
      when(() => mockOrderService.checkoutInit(branchId: 2))
          .thenAnswer((_) async => {
        'data': {
          'branch_id':  2,
          'branches':   [],
          'city_areas': [],
          'subtotal':   500,
        },
      });

      final notifier = container.read(orderProvider.notifier);

      // ── Act ──────────────────────────────────────────────────────
      // Branch 1 चा call सुरू करा, पण await करू नका — अजून pending आहे.
      final future1 = notifier.getCheckoutInit(branchId: 1);

      // वापरकर्त्याने पटकन Branch 2 निवडलं — हे लगेच पूर्ण होतं.
      await notifier.getCheckoutInit(branchId: 2);

      // आता Branch 1 चा जुना response उशिरा येऊ द्या.
      branch1Completer.complete({
        'data': {
          'branch_id':  1,
          'branches':   [],
          'city_areas': [],
          'subtotal':   999, // ✅ ही जुनी/चुकीची value असावी, state मध्ये येता कामा नये
        },
      });
      await future1; // stale response आता process होईल, पण drop व्हायला हवा

      // ── Assert: state अजूनही Branch 2 चीच असावी ──────────────────────
      final state = container.read(orderProvider);
      expect(state.selectedBranchId, 2);
      expect(state.subtotal, 500.0);
    });
  });

  group('OrderNotifier.selectArea', () {
    test('area निवडल्यावर shipping/subtotal/grandTotal summary मधून अपडेट होतात', () async {
      when(() => mockOrderService.checkoutSummary(countryId: any(named: 'countryId')))
          .thenAnswer((_) async => {
        'data': {
          'shipping_charge': '50.00',
          'subtotal':         '1,000.00', // ✅ comma असलेला amount
          'discount':         '0.00',
          'grand_total':      '1,050.00',
          'advance_amount':   '200.00',
        },
      });

      final notifier = container.read(orderProvider.notifier);
      await notifier.selectArea(3);

      final state = container.read(orderProvider);
      expect(state.selectedAreaId, 3);
      expect(state.shippingCharge, 50.0);
      expect(state.subtotal, 1000.0); // comma बरोबर parse झाला
      expect(state.grandTotal, 1050.0);
      expect(state.isInitLoading, false);
    });
  });

  group('OrderNotifier.applyCoupon', () {
    test('valid coupon लागल्यास couponCode/discount state मध्ये अपडेट होतात', () async {
      when(() => mockOrderService.applyCoupon(
        code:      any(named: 'code'),
        countryId: any(named: 'countryId'),
      )).thenAnswer((_) async => {
        'data': {
          'coupon_code':  'SAVE10',
          'discount':     '100.00',
          'grand_total':  '900.00',
          'subtotal':     '1,000.00',
        },
      });

      final notifier = container.read(orderProvider.notifier);
      final result = await notifier.applyCoupon('SAVE10');

      final state = container.read(orderProvider);
      expect(result, true);
      expect(state.couponCode, 'SAVE10');
      expect(state.discount, 100.0);
      expect(state.couponError, null);
      expect(state.isCouponLoading, false);
    });

    test('invalid coupon लागल्यास couponError सेट होतो, result false', () async {
      when(() => mockOrderService.applyCoupon(
        code:      any(named: 'code'),
        countryId: any(named: 'countryId'),
      )).thenThrow(Exception('Invalid coupon'));

      final notifier = container.read(orderProvider.notifier);
      final result = await notifier.applyCoupon('INVALID');

      final state = container.read(orderProvider);
      expect(result, false);
      expect(state.couponError, 'Invalid or expired coupon code');
      expect(state.isCouponLoading, false);
    });
  });

  group('OrderNotifier.processOrder', () {
    // helper — प्रत्येक टेस्टमध्ये पुन्हा पुन्हा लिहिण्याऐवजी
    Future<bool> callProcessOrder(OrderNotifier notifier) {
      return notifier.processOrder(
        firstName: 'Rahul', lastName: 'Sharma', email: 'rahul@test.com',
        branchId: 1, country: 10, address: '123 Main St', city: 'Pune',
        zip: '411001', mobile: '9999999999', bookingDate: '2026-08-01',
        bookingTime: '10:00 AM',
      );
    }

    test('यशस्वी झाल्यास selectedOrder/redirectUrl सेट होतात आणि orders refresh होतात', () async {
      when(() => mockOrderService.processOrder(
        firstName:   any(named: 'firstName'),
        lastName:    any(named: 'lastName'),
        email:       any(named: 'email'),
        branchId:    any(named: 'branchId'),
        country:     any(named: 'country'),
        apartment:   any(named: 'apartment'),
        address:     any(named: 'address'),
        city:        any(named: 'city'),
        zip:         any(named: 'zip'),
        mobile:      any(named: 'mobile'),
        bookingDate: any(named: 'bookingDate'),
        bookingTime: any(named: 'bookingTime'),
        orderNotes:  any(named: 'orderNotes'),
      )).thenAnswer((_) async => {
        'data': {'id': 99, 'redirect_url': 'https://pay.example.com/99'},
      });

      when(() => mockOrderService.getOrders(
        status: any(named: 'status'),
        page:   any(named: 'page'),
      )).thenAnswer((_) async => {'data': {'orders': []}});

      final notifier = container.read(orderProvider.notifier);
      final result = await callProcessOrder(notifier);

      final state = container.read(orderProvider);
      expect(result, true);
      expect(state.selectedOrder?['id'], 99);
      expect(state.redirectUrl, 'https://pay.example.com/99');
      expect(state.isDeletionBlocked, false);
      verify(() => mockOrderService.getOrders(
        status: any(named: 'status'),
        page:   any(named: 'page'),
      )).called(1);
    });

    test('DPDPA pending-deletion (403) आल्यास isDeletionBlocked true होतो', () async {
      when(() => mockOrderService.processOrder(
        firstName:   any(named: 'firstName'),
        lastName:    any(named: 'lastName'),
        email:       any(named: 'email'),
        branchId:    any(named: 'branchId'),
        country:     any(named: 'country'),
        apartment:   any(named: 'apartment'),
        address:     any(named: 'address'),
        city:        any(named: 'city'),
        zip:         any(named: 'zip'),
        mobile:      any(named: 'mobile'),
        bookingDate: any(named: 'bookingDate'),
        bookingTime: any(named: 'bookingTime'),
        orderNotes:  any(named: 'orderNotes'),
      )).thenThrow(AccountDeletionPendingException('Account pending deletion.'));

      final notifier = container.read(orderProvider.notifier);
      final result = await callProcessOrder(notifier);

      final state = container.read(orderProvider);
      expect(result, false);
      expect(state.isDeletionBlocked, true);
      expect(state.error, 'Account pending deletion.');
    });

    test('इतर कुठलीही error आल्यास फक्त error state सेट होते, isDeletionBlocked false राहतो', () async {
      when(() => mockOrderService.processOrder(
        firstName:   any(named: 'firstName'),
        lastName:    any(named: 'lastName'),
        email:       any(named: 'email'),
        branchId:    any(named: 'branchId'),
        country:     any(named: 'country'),
        apartment:   any(named: 'apartment'),
        address:     any(named: 'address'),
        city:        any(named: 'city'),
        zip:         any(named: 'zip'),
        mobile:      any(named: 'mobile'),
        bookingDate: any(named: 'bookingDate'),
        bookingTime: any(named: 'bookingTime'),
        orderNotes:  any(named: 'orderNotes'),
      )).thenThrow(Exception('Server error'));

      final notifier = container.read(orderProvider.notifier);
      final result = await callProcessOrder(notifier);

      final state = container.read(orderProvider);
      expect(result, false);
      expect(state.isDeletionBlocked, false);
      expect(state.error, contains('Server error'));
    });
  });
}