// lib/providers/cart_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cart_service.dart';

class CartState {
  final bool isLoading;
  final List<dynamic> cartItems;
  final int cartCount;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String? couponCode;
  final String? error;

  // ✅ NEW: branch/city pricing state
  final int? selectedBranchId;
  final bool isBranchLoading;
  final String? branchError;
  // rowId -> {available, price_per_unit, final_price, sqft}
  final Map<String, dynamic> branchPrices;
  // list of {rowId, name} not available in the selected city
  final List<dynamic> unavailableInBranch;

  const CartState({
    this.isLoading      = false,
    this.cartItems      = const [],
    this.cartCount      = 0,
    this.totalAmount    = 0.0,
    this.discountAmount = 0.0,
    this.finalAmount    = 0.0,
    this.couponCode,
    this.error,
    this.selectedBranchId,
    this.isBranchLoading = false,
    this.branchError,
    this.branchPrices = const {},
    this.unavailableInBranch = const [],
  });

  bool get hasBranchSelected => selectedBranchId != null;

  CartState copyWith({
    bool? isLoading,
    List<dynamic>? cartItems,
    int? cartCount,
    double? totalAmount,
    double? discountAmount,
    double? finalAmount,
    String? couponCode,
    String? error,
    int? selectedBranchId,
    bool? isBranchLoading,
    String? branchError,
    Map<String, dynamic>? branchPrices,
    List<dynamic>? unavailableInBranch,
  }) {
    return CartState(
      isLoading:      isLoading      ?? this.isLoading,
      cartItems:      cartItems      ?? this.cartItems,
      cartCount:      cartCount      ?? this.cartCount,
      totalAmount:    totalAmount    ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount:    finalAmount    ?? this.finalAmount,
      couponCode:     couponCode     ?? this.couponCode,
      error:          error          ?? this.error,
      selectedBranchId:    selectedBranchId    ?? this.selectedBranchId,
      isBranchLoading:     isBranchLoading      ?? this.isBranchLoading,
      branchError:         branchError,
      branchPrices:        branchPrices         ?? this.branchPrices,
      unavailableInBranch: unavailableInBranch  ?? this.unavailableInBranch,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final CartService _cartService;

  // ✅ CHANGED (testability साठी): आधी `final CartService _cartService =
  // CartService();` कायमचं fixed होतं — टेस्टमध्ये mock घुसवता येत
  // नव्हता. आता `cartService` हा optional named parameter आहे:
  //   - खऱ्या app मध्ये काहीच बदलत नाही (provider definition मध्ये
  //     cartService पास केलेला नाही, त्यामुळे `?? CartService()` कायम
  //     trigger होतं).
  //   - टेस्टमध्ये CartNotifier(cartService: mockCartService) असं करून
  //     खोटा (mock) service आत घुसवता येतो.
  CartNotifier({CartService? cartService})
      : _cartService = cartService ?? CartService(),
        super(const CartState()) {
    _init();
  }

  // ✅ CHANGED: no more auto-restoring the last-picked city from
  // SharedPreferences. Every time the Cart screen loads (fresh app
  // launch, or coming back to it), city selection starts blank and the
  // user must explicitly pick it again — this was a deliberate product
  // decision to avoid stale/wrong-city pricing being silently applied.
  Future<void> _init() async {
    await getCart();
  }

  Future<void> getCart() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _cartService.getCart();
      state = state.copyWith(
        isLoading:      false,
        cartItems:      response['cart_items']     ?? [],
        cartCount:      response['cart_count']     ?? 0,
        totalAmount:    (response['total_amount']  ?? 0.0).toDouble(),
        discountAmount: (response['discount']      ?? 0.0).toDouble(),
        finalAmount:    (response['final_amount']  ?? 0.0).toDouble(),
        couponCode:     response['coupon_code'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ✅ CHANGED: no longer persists the chosen city to SharedPreferences —
  // selection is intentionally session-only now (see _init above), so
  // every fresh visit to Cart requires picking the city again.
  Future<bool> setBranch(int branchId) async {
    state = state.copyWith(isBranchLoading: true, branchError: null);
    try {
      final result = await _cartService.setBranch(branchId);

      state = state.copyWith(
        isBranchLoading:     false,
        selectedBranchId:    branchId,
        branchPrices:        result['prices'] ?? {},
        unavailableInBranch: result['unavailable'] ?? [],
      );

      // Refresh the cart itself — GET /cart's subtotal is branch-aware
      // once a branch is set, so this pulls in the correct total/discount.
      await getCart();
      return true;
    } catch (e) {
      state = state.copyWith(isBranchLoading: false, branchError: e.toString());
      return false;
    }
  }

  // ✅ NEW: Re-fetch branch-specific prices for the current cart contents
  // without re-calling setBranch — e.g. after adding/removing an item
  // while a branch is already selected.
  Future<void> refreshBranchPrices() async {
    if (state.selectedBranchId == null) return;
    state = state.copyWith(isBranchLoading: true, branchError: null);
    try {
      final result = await _cartService.getBranchPrices();
      state = state.copyWith(
        isBranchLoading:     false,
        branchPrices:        result['prices'] ?? {},
        unavailableInBranch: result['unavailable'] ?? [],
      );
    } catch (e) {
      state = state.copyWith(isBranchLoading: false, branchError: e.toString());
    }
  }

  /// Look up the branch-specific final price for a cart rowId.
  /// Returns null if branch prices haven't loaded or item isn't available.
  double? finalPriceFor(String rowId) {
    final entry = state.branchPrices[rowId];
    if (entry == null || entry['available'] != true) return null;
    return (entry['final_price'] as num?)?.toDouble();
  }

  bool isUnavailableInBranch(String rowId) {
    return state.unavailableInBranch.any((u) => u['rowId'] == rowId);
  }

  // ✅ FIX: quantity param काढला — service मध्ये नाही
  Future<bool> addToCart({
    required int productId,
    Map<String, dynamic>? extras,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _cartService.addToCart(
        productId: productId,
        extras:    extras,
      );
      await getCart();
      if (state.hasBranchSelected) await refreshBranchPrices();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ✅ FIX: params आता service शी match होतात
  Future<bool> addFlatToCart({
    required int mainProductId,
    required double sqft,
    required List<Map<String, dynamic>> addons,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _cartService.addFlatToCart(
        mainProductId: mainProductId,
        sqft:          sqft,
        addons:        addons,
      );
      await getCart();
      if (state.hasBranchSelected) await refreshBranchPrices();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ✅ FIX: cartItemId → rowId, quantity → qty
  Future<bool> updateCartItem({
    required String rowId,
    required int qty,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _cartService.updateCartItem(
        rowId: rowId,
        qty:   qty,
      );
      await getCart();
      if (state.hasBranchSelected) await refreshBranchPrices();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ✅ OK — rowId string आहे, service शी match
  Future<bool> removeCartItem(String rowId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _cartService.removeCartItem(rowId);
      await getCart();
      if (state.hasBranchSelected) await refreshBranchPrices();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> clearCart() async {
    // ✅ CHANGED: city choice no longer carries across an order either —
    // since selection is session-only now (not persisted), resetting the
    // whole CartState on clear (including selectedBranchId) is consistent
    // with "pick city fresh every time".
    state = const CartState();
    return true;
  }

  Future<bool> applyCoupon(String couponCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _cartService.applyCoupon(couponCode);
      await getCart();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> removeCoupon() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _cartService.removeCoupon();
      await getCart();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
      (ref) => CartNotifier(),
);

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).cartCount;
});