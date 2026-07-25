// lib/services/product_service.dart

import 'api_client.dart';

class ProductService {
  final ApiClient _api;

  // ✅ CHANGED (testability साठी): आधी `final ApiClient _api = ApiClient();`
  // कायमचं fixed होतं. आता optional named parameter — खऱ्या app मध्ये
  // काहीच बदलत नाही, टेस्टमध्ये ProductService(apiClient: mockApiClient)
  // करून mock घुसवता येतो.
  ProductService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getProducts({
    String? category,
    String? search,
    int page = 1,
  }) async {
    final response = await _api.get(
      '/products',
      queryParams: {
        if (category != null) 'category': category,
        if (search != null)   'search':   search,
        'page': page,
      },
    );
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> getProductDetail(int id) async {
    final response = await _api.get('/products/$id');
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> getFurnishedFlats() async {
    final response = await _api.get('/products/furnished-flats');
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> getUnfurnishedFlats() async {
    final response = await _api.get('/products/unfurnished-flats');
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> getFlatCategory(String type) async {
    final response = await _api.get(
      '/products/flat-category',
      queryParams: {'type': type},
    );
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> getBHKList({
    required String type,
    required String bhk,
  }) async {
    final response = await _api.get(
      '/products/bhk-list',
      queryParams: {
        'type': type,
        'bhk':  bhk,
      },
    );
    return _unwrap(response.data);
  }

  // ✅ FIX: query param 'q' → 'keyword'
  Future<Map<String, dynamic>> searchProducts(String query) async {
    final response = await _api.get(
      '/products/search',
      queryParams: {'keyword': query},
    );
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> getProductReviews(int productId) async {
    final response = await _api.get('/products/$productId/reviews');
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> addProductReview({
    required int productId,
    required int rating,
    required String review,
  }) async {
    final response = await _api.post(
      '/products/$productId/reviews',
      data: {
        'rating': rating,
        'review': review,
      },
    );
    return _unwrap(response.data);
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data')) {
        final inner = data['data'];
        if (inner is Map<String, dynamic>) {
          return inner;
        } else if (inner is List) {
          return {'products': inner};
        }
      }
      return data;
    }
    return {};
  }
}