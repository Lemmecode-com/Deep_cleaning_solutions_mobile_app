// test/providers/order_notifier_test.dart
//
// ✅ This test checks OrderNotifier's checkout/orders logic — without
// making a real API call. OrderService is mocked. The most important test:
// specifically checks the "race condition guard" — when the branch is
// switched quickly, an old (stale) /checkout/init response must not
// override the newer response.

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
    test('fills the orders list into state when getOrders succeeds', () async {
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

    test('sets error state when getOrders fails', () async {
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
    test('state stays on the new branch even if a stale response arrives late', () async {
      // ── Arrange ──────────────────────────────────────────────────
      // Deliberately "stall" Branch 1's call (using a Completer) — as if
      // that network request is still in flight.
      final branch1Completer = Completer<Map<String, dynamic>>();
      when(() => mockOrderService.checkoutInit(branchId: 1))
          .thenAnswer((_) => branch1Completer.future);

      // Branch 2's call resolves right away (near-synchronously).
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
      // Start Branch 1's call, but don't await it yet — it's still pending.
      final future1 = notifier.getCheckoutInit(branchId: 1);

      // The user quickly selected Branch 2 — this completes right away.
      await notifier.getCheckoutInit(branchId: 2);

      // Now let Branch 1's old response arrive late.
      branch1Completer.complete({
        'data': {
          'branch_id':  1,
          'branches':   [],
          'city_areas': [],
          'subtotal':   999, // ✅ this should be a stale/wrong value that must not land in state
        },
      });
      await future1; // the stale response will now be processed, but should be dropped

      // ── Assert: state should still be Branch 2's ──────────────────────
      final state = container.read(orderProvider);
      expect(state.selectedBranchId, 2);
      expect(state.subtotal, 500.0);
    });
  });

  group('OrderNotifier.selectArea', () {
    test('shipping/subtotal/grandTotal get updated from the summary when an area is selected', () async {
      when(() => mockOrderService.checkoutSummary(countryId: any(named: 'countryId')))
          .thenAnswer((_) async => {
        'data': {
          'shipping_charge': '50.00',
          'subtotal':         '1,000.00', // ✅ amount with a comma
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
      expect(state.subtotal, 1000.0); // the comma was parsed correctly
      expect(state.grandTotal, 1050.0);
      expect(state.isInitLoading, false);
    });
  });

  group('OrderNotifier.applyCoupon', () {
    test('couponCode/discount get updated in state when a valid coupon is applied', () async {
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

    test('couponError is set and result is false when an invalid coupon is applied', () async {
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
    // helper — instead of rewriting this in every single test
    Future<bool> callProcessOrder(OrderNotifier notifier) {
      return notifier.processOrder(
        firstName: 'Rahul', lastName: 'Sharma', email: 'rahul@test.com',
        branchId: 1, country: 10, address: '123 Main St', city: 'Pune',
        zip: '411001', mobile: '9999999999', bookingDate: '2026-08-01',
        bookingTime: '10:00 AM',
      );
    }

    test('selectedOrder/redirectUrl get set and orders get refreshed on success', () async {
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

    test('isDeletionBlocked becomes true when DPDPA pending-deletion (403) occurs', () async {
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

    test('for any other error, only the error state is set, isDeletionBlocked stays false', () async {
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
