// test/providers/cart_notifier_test.dart
//
// ✅ This test checks CartNotifier's cart-management logic — without making
// a real API call or using the internet. A fake (mock) CartService is used
// in place of CartService — so we can control it: "when the getCart call
// comes, give this data" or "when the addToCart call comes, throw an
// error".

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/providers/cart_provider.dart';
import 'package:dcs_app/services/cart_service.dart';

// ── Step 1: Create a fake (mock) CartService ────────────────────────
class MockCartService extends Mock implements CartService {}

// The default (empty cart) response for getCart() — the same one is used
// in setUp for most tests, so it's kept here once as a helper.
Map<String, dynamic> _emptyCartResponse() => {
  'cart_items':   <dynamic>[],
  'cart_count':   0,
  'total_amount': 0.0,
  'discount':     0.0,
  'final_amount': 0.0,
  'coupon_code':  null,
};

void main() {
  late MockCartService mockCartService;
  late ProviderContainer container;

  // mocktail needs the Map/List arguments used in addToCart/applyCoupon
  // etc. (fallback values) registered beforehand, otherwise using
  // any(named: ..) throws an error.
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockCartService = MockCartService();

    // ✅ As soon as CartNotifier's constructor starts, _init() → getCart()
    // gets called. If this isn't mocked, an error will occur before the
    // very first test even starts, so we set up a default "empty cart"
    // behavior beforehand.
    when(() => mockCartService.getCart())
        .thenAnswer((_) async => _emptyCartResponse());

    container = ProviderContainer(
      overrides: [
        // ✅ Step 2: Tell cartProvider — don't use the real CartService(),
        // use our mockCartService.
        cartProvider.overrideWith(
              (ref) => CartNotifier(cartService: mockCartService),
        ),
      ],
    );

    addTearDown(container.dispose);
  });

  group('CartNotifier.getCart', () {
    test('fills cart items/count/totals into state when getCart succeeds', () async {
      // ── Arrange ──────────────────────────────────────────────────
      when(() => mockCartService.getCart()).thenAnswer((_) async => {
        'cart_items': [
          {'rowId': 'r1', 'name': 'Deep Cleaning', 'qty': 2},
        ],
        'cart_count':   2,
        'total_amount': 1200.0,
        'discount':     200.0,
        'final_amount': 1000.0,
        'coupon_code':  'SAVE200',
      });

      // ── Act ──────────────────────────────────────────────────────
      final notifier = container.read(cartProvider.notifier);
      await notifier.getCart();

      // ── Assert ───────────────────────────────────────────────────
      final state = container.read(cartProvider);
      expect(state.isLoading, false);
      expect(state.cartCount, 2);
      expect(state.cartItems.length, 1);
      expect(state.totalAmount, 1200.0);
      expect(state.discountAmount, 200.0);
      expect(state.finalAmount, 1000.0);
      expect(state.couponCode, 'SAVE200');
      expect(state.error, null);
    });

    test('sets error state and keeps cart empty when getCart fails', () async {
      // ── Arrange ──────────────────────────────────────────────────
      when(() => mockCartService.getCart())
          .thenThrow(Exception('Network error'));

      // ── Act ──────────────────────────────────────────────────────
      final notifier = container.read(cartProvider.notifier);
      await notifier.getCart();

      // ── Assert ───────────────────────────────────────────────────
      final state = container.read(cartProvider);
      expect(state.isLoading, false);
      expect(state.error, contains('Network error'));
      expect(state.cartCount, 0);
    });
  });

  group('CartNotifier.addToCart', () {
    test('refreshes the cart and returns true when addToCart succeeds', () async {
      // ── Arrange: the add call succeeds, and the following getCart returns the updated cart ──
      when(() => mockCartService.addToCart(
        productId: any(named: 'productId'),
        extras:    any(named: 'extras'),
      )).thenAnswer((_) async => {'status': true});

      when(() => mockCartService.getCart()).thenAnswer((_) async => {
        'cart_items':   [
          {'rowId': 'r1', 'name': 'Sofa Cleaning', 'qty': 1},
        ],
        'cart_count':   1,
        'total_amount': 500.0,
        'discount':     0.0,
        'final_amount': 500.0,
        'coupon_code':  null,
      });

      // ── Act ──────────────────────────────────────────────────────
      final notifier = container.read(cartProvider.notifier);
      final result = await notifier.addToCart(productId: 42);

      // ── Assert ───────────────────────────────────────────────────
      final state = container.read(cartProvider);
      expect(result, true);
      expect(state.isLoading, false);
      expect(state.cartCount, 1);
      expect(state.error, null);
      verify(() => mockCartService.addToCart(
        productId: 42,
        extras:    null,
      )).called(1);
    });

    test('sets error state and returns false when addToCart fails', () async {
      // ── Arrange ──────────────────────────────────────────────────
      when(() => mockCartService.addToCart(
        productId: any(named: 'productId'),
        extras:    any(named: 'extras'),
      )).thenThrow(Exception('Product out of stock'));

      // ── Act ──────────────────────────────────────────────────────
      final notifier = container.read(cartProvider.notifier);
      final result = await notifier.addToCart(productId: 99);

      // ── Assert ───────────────────────────────────────────────────
      final state = container.read(cartProvider);
      expect(result, false);
      expect(state.isLoading, false);
      expect(state.error, contains('Product out of stock'));
    });
  });

  group('CartNotifier.removeCartItem', () {
    test('refreshes the cart and returns true when removeCartItem succeeds', () async {
      // ── Arrange ──────────────────────────────────────────────────
      when(() => mockCartService.removeCartItem(any()))
          .thenAnswer((_) async => {'status': true});

      when(() => mockCartService.getCart())
          .thenAnswer((_) async => _emptyCartResponse());

      // ── Act ──────────────────────────────────────────────────────
      final notifier = container.read(cartProvider.notifier);
      final result = await notifier.removeCartItem('r1');

      // ── Assert ───────────────────────────────────────────────────
      final state = container.read(cartProvider);
      expect(result, true);
      expect(state.cartCount, 0);
      expect(state.error, null);
      verify(() => mockCartService.removeCartItem('r1')).called(1);
    });

    test('sets error state when removeCartItem fails', () async {
      // ── Arrange ──────────────────────────────────────────────────
      when(() => mockCartService.removeCartItem(any()))
          .thenThrow(Exception('Item not found'));

      // ── Act ──────────────────────────────────────────────────────
      final notifier = container.read(cartProvider.notifier);
      final result = await notifier.removeCartItem('r-missing');

      // ── Assert ───────────────────────────────────────────────────
      final state = container.read(cartProvider);
      expect(result, false);
      expect(state.error, contains('Item not found'));
    });
  });

  group('CartNotifier.applyCoupon', () {
    test('updated discount/coupon land in state when applyCoupon succeeds', () async {
      // ── Arrange ──────────────────────────────────────────────────
      when(() => mockCartService.applyCoupon(any()))
          .thenAnswer((_) async => {'status': true});

      when(() => mockCartService.getCart()).thenAnswer((_) async => {
        'cart_items':   <dynamic>[],
        'cart_count':   0,
        'total_amount': 1000.0,
        'discount':     100.0,
        'final_amount': 900.0,
        'coupon_code':  'WELCOME100',
      });

      // ── Act ──────────────────────────────────────────────────────
      final notifier = container.read(cartProvider.notifier);
      final result = await notifier.applyCoupon('WELCOME100');

      // ── Assert ───────────────────────────────────────────────────
      final state = container.read(cartProvider);
      expect(result, true);
      expect(state.couponCode, 'WELCOME100');
      expect(state.discountAmount, 100.0);
      expect(state.error, null);
      verify(() => mockCartService.applyCoupon('WELCOME100')).called(1);
    });

    test('sets error state when applyCoupon fails for an invalid code', () async {
      // ── Arrange ──────────────────────────────────────────────────
      when(() => mockCartService.applyCoupon(any()))
          .thenThrow(Exception('Invalid coupon code'));

      // ── Act ──────────────────────────────────────────────────────
      final notifier = container.read(cartProvider.notifier);
      final result = await notifier.applyCoupon('INVALID');

      // ── Assert ───────────────────────────────────────────────────
      final state = container.read(cartProvider);
      expect(result, false);
      expect(state.error, contains('Invalid coupon code'));
      expect(state.couponCode, null);
    });
  });

  group('CartNotifier.clearCart', () {
    test('the entire state (including branch/coupon) becomes empty after clearCart', () async {
      // ── Arrange: first build a state that already has some data ─────────────
      when(() => mockCartService.getCart()).thenAnswer((_) async => {
        'cart_items':   [
          {'rowId': 'r1', 'name': 'AC Service', 'qty': 1},
        ],
        'cart_count':   1,
        'total_amount': 800.0,
        'discount':     0.0,
        'final_amount': 800.0,
        'coupon_code':  'SAVE10',
      });

      final notifier = container.read(cartProvider.notifier);
      await notifier.getCart();
      expect(container.read(cartProvider).cartCount, 1); // sanity check

      // ── Act ──────────────────────────────────────────────────────
      final result = await notifier.clearCart();

      // ── Assert: should look like a brand new (default) CartState ──────────
      final state = container.read(cartProvider);
      expect(result, true);
      expect(state.cartItems, isEmpty);
      expect(state.cartCount, 0);
      expect(state.totalAmount, 0.0);
      expect(state.couponCode, null);
      expect(state.selectedBranchId, null); // ✅ branch selection also resets
      expect(state.error, null);
    });
  });
}
