// lib/services/blog_service.dart

import 'api_client.dart';

class BlogService {
  final ApiClient _api;

  // ✅ CHANGED (testability साठी): आधी `final ApiClient _api = ApiClient();`
  // कायमचं fixed होतं. आता optional named parameter — टेस्टमध्ये
  // BlogService(apiClient: mockApiClient) करून mock घुसवता येतो.
  BlogService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  // ── Get All Blogs ─────────────────────────────────────────────────
  // ✅ API doc: GET /blogs
  Future<Map<String, dynamic>> getBlogs({
    String? category,
    String? search,
    int page = 1,
  }) async {
    final response = await _api.get(
      '/blogs',
      queryParams: {
        if (category != null) 'category': category,
        if (search != null)   'search':   search,
        'page': page,
      },
    );
    return response.data;
  }

  // ── Get Blog Detail ───────────────────────────────────────────────
  // ✅ API doc: GET /blogs/{slug}
  Future<Map<String, dynamic>> getBlogDetail(String slug) async {
    final response = await _api.get('/blogs/$slug');
    return response.data;
  }

  // ── Add Blog Comment ──────────────────────────────────────────────
  // ✅ API doc: POST /blogs/{blog}/comment
  Future<Map<String, dynamic>> addComment({
    required int blogId,
    required String comment,
  }) async {
    final response = await _api.post(
      '/blogs/$blogId/comment',
      data: {'comment': comment},
    );
    return response.data;
  }

  // ── Like / Unlike Blog ────────────────────────────────────────────
  // ✅ API doc: POST /blogs/{blog}/like
  Future<Map<String, dynamic>> toggleLike(int blogId) async {
    final response = await _api.post('/blogs/$blogId/like', data: {});
    return response.data;
  }
}