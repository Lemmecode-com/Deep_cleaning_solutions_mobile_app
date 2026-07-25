// lib/providers/wishlist_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/wishlist_service.dart';
import 'auth_provider.dart';

class WishlistState {
  final bool isLoading;
  final List<dynamic> wishlistItems;
  final int wishlistCount;
  final String? error;

  const WishlistState({
    this.isLoading     = false,
    this.wishlistItems = const [],
    this.wishlistCount = 0,
    this.error,
  });

  WishlistState copyWith({
    bool? isLoading,
    List<dynamic>? wishlistItems,
    int? wishlistCount,
    String? error,
  }) {
    return WishlistState(
      isLoading:     isLoading     ?? this.isLoading,
      wishlistItems: wishlistItems ?? this.wishlistItems,
      wishlistCount: wishlistCount ?? this.wishlistCount,
      error:         error         ?? this.error,
    );
  }
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistService _wishlistService;
  final Ref _ref;

  // ✅ CHANGED (testability साठी): आधी `final WishlistService
  // _wishlistService = WishlistService();` कायमचं fixed होतं. आता
  // optional named parameter — टेस्टमध्ये
  // WishlistNotifier(ref, wishlistService: mockWishlistService) करून
  // mock घुसवता येतो.
  WishlistNotifier(this._ref, {WishlistService? wishlistService})
      : _wishlistService = wishlistService ?? WishlistService(),
        super(const WishlistState());

  bool _isLoggedIn() => _ref.read(authProvider).isLoggedIn;

  // ── Get Wishlist ───────────────────────────────────────────────────
  Future<void> getWishlist() async {
    if (!_isLoggedIn()) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _wishlistService.getWishlist();
      final items = response['items'] ?? [];
      state = state.copyWith(
        isLoading:     false,
        wishlistItems: items,
        wishlistCount: response['count'] ?? items.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Add to Wishlist ────────────────────────────────────────────────
  Future<String> addToWishlist(int productId) async {
    if (!_isLoggedIn()) return 'login_required';

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _wishlistService.addToWishlist(productId);
      await getWishlist();
      return 'success';
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 'error';
    }
  }

  // ── Remove from Wishlist ───────────────────────────────────────────
  Future<bool> removeFromWishlist(int productId) async {
    if (!_isLoggedIn()) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _wishlistService.removeFromWishlist(productId);
      await getWishlist();
      return true;
    } catch (e) {
      final updated = state.wishlistItems
          .where((item) => (item['id'] as int?) != productId)
          .toList();
      state = state.copyWith(
        isLoading:     false,
        wishlistItems: updated,
        wishlistCount: updated.length,
        error:         null,
      );
      return true;
    }
  }

  // ── Toggle Wishlist ────────────────────────────────────────────────
  Future<String> toggleWishlist(int productId) async {
    if (!_isLoggedIn()) return 'login_required';

    final inWishlist = state.wishlistItems
        .any((item) => (item['id'] as int?) == productId);
    if (inWishlist) {
      final success = await removeFromWishlist(productId);
      return success ? 'removed' : 'error';
    } else {
      return await addToWishlist(productId);
    }
  }

  // ── Clear Wishlist ─────────────────────────────────────────────────
  Future<bool> clearWishlist() async {
    state = const WishlistState();
    return true;
  }

  // ── Check Wishlist ─────────────────────────────────────────────────
  bool isInWishlist(int productId) {
    if (!_isLoggedIn()) return false;
    return state.wishlistItems
        .any((item) => (item['id'] as int?) == productId);
  }

  // ✅ FIX: तोच copyWith null-clearing bug (product_provider मध्ये सापडला
  // होता तोच) — `null ?? this.error` जुनाच error ठेवतो, त्यामुळे आधी हे
  // function प्रत्यक्षात काहीच करत नव्हतं. State थेट rebuild करून खरंच
  // clear करतो.
  void clearError() {
    state = WishlistState(
      isLoading:     state.isLoading,
      wishlistItems: state.wishlistItems,
      wishlistCount: state.wishlistCount,
      error:         null,
    );
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
      (ref) => WishlistNotifier(ref),
);

final wishlistCountProvider = Provider<int>((ref) {
  return ref.watch(wishlistProvider).wishlistCount;
});

// ✅ FIXED: state var directly depend ahe — real-time update hoil
final isInWishlistProvider = Provider.family<bool, int>((ref, productId) {
  final wishlistItems = ref.watch(wishlistProvider).wishlistItems;
  return wishlistItems.any((item) => (item['id'] as int?) == productId);
});