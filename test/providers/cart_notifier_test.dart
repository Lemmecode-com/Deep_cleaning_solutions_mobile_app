// test/providers/cart_notifier_test.dart
//
// ✅ हा टेस्ट CartNotifier चा cart-management logic तपासतो — खरा API call
// किंवा internet न वापरता. CartService च्या जागी खोटं (mock) CartService
// वापरलंय — त्यामुळे आपण control करू शकतो: "getCart call आला की हा data
// दे" किंवा "addToCart call आला की error फेकून टाक".

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/providers/cart_provider.dart';
import 'package:dcs_app/services/cart_service.dart';

// ── Step 1: खोटं (mock) CartService बनवा ────────────────────────────
class MockCartService extends Mock implements CartService {}

// getCart() चा डिफॉल्ट (रिकामी cart) response — बहुतेक टेस्टमध्ये
// setUp मध्ये हाच वापरला जातो, त्यामुळे इथे एकदाच helper म्हणून ठेवलाय.
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

  // mocktail ला addToCart/applyCoupon इ. मधले Map/List arguments
  // (fallback values) आधी registered लागतात, नाहीतर any(named: ..)
  // वापरताना error येतो.
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockCartService = MockCartService();

    // ✅ CartNotifier चा constructor सुरू होताच _init() → getCart() call
    // होतो. हे mock न केल्यास पहिलाच टेस्ट सुरू होण्याआधी error येईल,
    // म्हणून डिफॉल्ट "रिकामी cart" behavior आधीच सेट करून ठेवतोय.
    when(() => mockCartService.getCart())
        .thenAnswer((_) async => _emptyCartResponse());

    container = ProviderContainer(
      overrides: [
        // ✅ Step 2: cartProvider ला सांगा — खरं CartService() नको,
        // आपलं mockCartService वापर.
        cartProvider.overrideWith(
              (ref) => CartNotifier(cartService: mockCartService),
        ),
      ],
    );

    addTearDown(container.dispose);
  });

  group('CartNotifier.getCart', () {
    test('getCart यशस्वी झाल्यास cart items/count/totals state मध्ये भरतात', () async {
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

    test('getCart fail झाल्यास error state सेट होते, cart रिकामीच राहते', () async {
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
    test('addToCart यशस्वी झाल्यास cart refresh होते आणि true return होतं', () async {
      // ── Arrange: add call ठीक आहे, आणि नंतरचं getCart अपडेटेड cart देतं ──
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

    test('addToCart fail झाल्यास error state सेट होते आणि false return होतं', () async {
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
    test('removeCartItem यशस्वी झाल्यास cart refresh होते आणि true return होतं', () async {
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

    test('removeCartItem fail झाल्यास error state सेट होते', () async {
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
    test('applyCoupon यशस्वी झाल्यास updated discount/coupon state मध्ये येतो', () async {
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

    test('applyCoupon invalid code साठी fail झाल्यास error state सेट होते', () async {
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
    test('clearCart केल्यावर संपूर्ण state (branch/coupon सकट) रिकामी होते', () async {
      // ── Arrange: आधी काहीतरी data असलेली state तयार करा ─────────────
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

      // ── Assert: नवीन कोरी (default) CartState सारखीच असावी ──────────
      final state = container.read(cartProvider);
      expect(result, true);
      expect(state.cartItems, isEmpty);
      expect(state.cartCount, 0);
      expect(state.totalAmount, 0.0);
      expect(state.couponCode, null);
      expect(state.selectedBranchId, null); // ✅ branch selection सुद्धा reset
      expect(state.error, null);
    });
  });
}