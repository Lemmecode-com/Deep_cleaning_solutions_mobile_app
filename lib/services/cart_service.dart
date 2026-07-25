// lib/services/cart_service.dart

import 'api_client.dart';

// ✅ shared helper — backend sends amounts >= 1000 with a
// thousands-separator comma (e.g. "6,600.00"), which double.tryParse()
// can't handle and silently returns null -> 0. Strip commas first.
double _parseAmount(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '')) ?? 0.0;
}

class CartService {
  final ApiClient _api;

  // ✅ CHANGED (testability साठी): आधी `final ApiClient _api = ApiClient();`
  // कायमचं fixed होतं. आता optional named parameter — खऱ्या app मध्ये
  // काहीच बदलत नाही (`?? ApiClient()` कायम trigger होतं, आणि ApiClient
  // स्वतः singleton असल्यामुळे तीच instance मिळते), टेस्टमध्ये
  // CartService(apiClient: mockApiClient) करून mock घुसवता येतो.
  CartService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getCart() async {
    final response = await _api.get('/cart');
    final data = response.data['data'] ?? {};
    return {
      'cart_items':   data['items']    ?? [],
      'cart_count':   data['count']    ?? 0,
      'total_amount': _parseAmount(data['subtotal']),
      'discount':     _parseAmount(data['discount']),
      'final_amount': _parseAmount(data['final_amount'] ?? data['subtotal']),
      'coupon_code':  data['coupon_code'],
    };
  }

  // ✅ FIX: product_id → id (API ला 'id' लागतो)
  Future<Map<String, dynamic>> addToCart({
    required int productId,
    Map<String, dynamic>? extras,
  }) async {
    final response = await _api.post(
      '/cart/add',
      data: {
        'id': productId,
        if (extras != null) ...extras,
      },
    );
    return response.data;
  }

  // ✅ FIX: product_id → id, units + unit_type API (cart/add-with-unit)
  Future<Map<String, dynamic>> addToCartWithUnit({
    required int productId,
    required int units,
    required String unitType,
  }) async {
    final response = await _api.post(
      '/cart/add-with-unit',
      data: {
        'id':        productId,
        'units':     units,
        'unit_type': unitType,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> addFlatToCart({
    required int mainProductId,
    required double sqft,
    required List<Map<String, dynamic>> addons,
  }) async {
    final response = await _api.post(
      '/cart/add-flat',
      data: {
        'main_product_id': mainProductId,
        'sqft':            sqft,
        'addons':          addons,
      },
    );
    // ✅ API error message throw kar
    if (response.data['status'] == false) {
      throw response.data['message'] ?? 'Failed to add to cart.';
    }
    return response.data;
  }

  // ✅ FIX: row_id → rowId, quantity → qty
  Future<Map<String, dynamic>> updateCartItem({
    required String rowId,
    required int qty,
  }) async {
    final response = await _api.put(
      '/cart/update',
      data: {
        'rowId': rowId,
        'qty':   qty,
      },
    );
    return response.data;
  }

  // ✅ FIX: row_id → rowId
  Future<Map<String, dynamic>> removeCartItem(String rowId) async {
    final response = await _api.delete(
      '/cart/item',
      data: {'rowId': rowId},
    );
    return response.data;
  }

  // ✅ FIX: coupon_code → code
  Future<Map<String, dynamic>> applyCoupon(String couponCode) async {
    final response = await _api.post(
      '/checkout/apply-coupon',
      data: {'code': couponCode},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> removeCoupon() async {
    final response = await _api.post('/checkout/remove-coupon', data: {});
    return response.data;
  }

  // ✅ FIX: product_id → id
  Future<Map<String, dynamic>> getCartRowId({
    required int productId,
  }) async {
    final response = await _api.post(
      '/cart/row-id',
      data: {'id': productId},
    );
    return response.data;
  }

  // ✅ NEW: Set the session's selected city/branch. Must be called before
  // checkout — all subsequent /cart, /checkout/init and /checkout/summary
  // subtotal calculations become branch-aware once this is set. Also
  // persists preferred_branch_id on the user record if logged in.
  // Returns branch-specific prices for all current cart items immediately
  // (same shape as getBranchPrices below).
  Future<Map<String, dynamic>> setBranch(int branchId) async {
    final response = await _api.post(
      '/cart/set-branch',
      data: {'branch_id': branchId},
    );
    if (response.data['status'] == false) {
      throw response.data['message'] ?? 'Could not set branch.';
    }
    return _parseBranchPrices(response.data);
  }

  // ✅ NEW: Get branch-specific prices for everything currently in the
  // cart, for whichever branch was set via setBranch(). Use this to
  // refresh city pricing after cart contents change (add/remove item)
  // without re-calling setBranch.
  Future<Map<String, dynamic>> getBranchPrices() async {
    final response = await _api.get('/cart/branch-prices');
    if (response.data['status'] == false) {
      throw response.data['message'] ?? 'Could not fetch branch prices.';
    }
    return _parseBranchPrices(response.data);
  }

  // Shared parser for both setBranch and getBranchPrices — same response shape.
  Map<String, dynamic> _parseBranchPrices(Map<String, dynamic> raw) {
    final data = raw['data'] ?? {};
    final pricesRaw = (data['prices'] as Map<String, dynamic>?) ?? {};

    // Keep prices keyed by rowId, but normalize numeric fields.
    final prices = <String, Map<String, dynamic>>{};
    pricesRaw.forEach((rowId, v) {
      if (v == null) {
        prices[rowId] = {'available': false};
      } else {
        final m = v as Map<String, dynamic>;
        prices[rowId] = {
          'available':      true,
          'price_per_unit': _parseAmount(m['price_per_unit']),
          'final_price':    _parseAmount(m['final_price']),
          'sqft':           m['sqft'],
        };
      }
    });

    final unavailableRaw = (data['unavailable'] as List<dynamic>?) ?? [];
    final unavailable = unavailableRaw
        .map((e) => {
      'rowId': e['rowId']?.toString() ?? '',
      'name':  e['name']?.toString() ?? '',
    })
        .toList();

    return {
      'branch_id':   data['branch_id'] ?? 0,
      'prices':      prices,
      'unavailable': unavailable,
      'subtotal':    _parseAmount(data['subtotal']),
    };
  }
}