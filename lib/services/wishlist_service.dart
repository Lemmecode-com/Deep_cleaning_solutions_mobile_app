// lib/services/wishlist_service.dart

import 'api_client.dart';

class WishlistService {
  final ApiClient _api;

  // ✅ CHANGED (testability साठी): आधी `final ApiClient _api = ApiClient();`
  // कायमचं fixed होतं. आता optional named parameter — टेस्टमध्ये
  // WishlistService(apiClient: mockApiClient) करून mock घुसवता येतो.
  WishlistService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  // ── Get Wishlist ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> getWishlist() async {
    final response = await _api.get('/wishlist');
    final data = response.data['data'] ?? {};
    return {
      'items': data['items'] ?? [],
      'count': data['count'] ?? 0,
    };
  }

  // ── Add to Wishlist ───────────────────────────────────────────────
  // ✅ POST /wishlist
  Future<Map<String, dynamic>> addToWishlist(int productId) async {
    final response = await _api.post(
      '/wishlist',
      data: {'product_id': productId},
    );
    return response.data;
  }

  // ── Remove from Wishlist ──────────────────────────────────────────
  // ⚠️ DELETE /wishlist — Backend bug आहे
  Future<Map<String, dynamic>> removeFromWishlist(int productId) async {
    final response = await _api.delete(
      '/wishlist',
      data: {'product_id': productId},
    );
    return response.data;
  }

  // ── Check Wishlist Status ─────────────────────────────────────────
  // ✅ POST /wishlist/check-status
  Future<Map<String, dynamic>> checkWishlistStatus(int productId) async {
    final response = await _api.post(
      '/wishlist/check-status',
      data: {'product_id': productId},
    );
    return response.data;
  }

  // ── Get Wishlist Count ────────────────────────────────────────────
  // ✅ GET /wishlist/count
  Future<int> getWishlistCount() async {
    final response = await _api.get('/wishlist/count');
    return response.data['data']?['count'] ?? 0;
  }
}