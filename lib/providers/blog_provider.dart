// lib/providers/blog_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/blog_service.dart';

class BlogState {
  final bool isLoading;
  final List<dynamic> blogs;
  final List<dynamic> categories;
  final Map<String, dynamic>? selectedBlog;
  final int selectedCategory;
  final String? error;

  const BlogState({
    this.isLoading        = false,
    this.blogs            = const [],
    this.categories       = const [],
    this.selectedBlog,
    this.selectedCategory = 0,
    this.error,
  });

  BlogState copyWith({
    bool? isLoading,
    List<dynamic>? blogs,
    List<dynamic>? categories,
    Map<String, dynamic>? selectedBlog,
    int? selectedCategory,
    String? error,
  }) {
    return BlogState(
      isLoading:        isLoading        ?? this.isLoading,
      blogs:            blogs            ?? this.blogs,
      categories:       categories       ?? this.categories,
      selectedBlog:     selectedBlog     ?? this.selectedBlog,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      error:            error            ?? this.error,
    );
  }
}

class BlogNotifier extends StateNotifier<BlogState> {
  final BlogService _blogService;

  // ✅ CHANGED (testability साठी): आधी `final BlogService _blogService =
  // BlogService();` कायमचं fixed होतं. आता optional named parameter —
  // टेस्टमध्ये BlogNotifier(blogService: mockBlogService) करून mock
  // घुसवता येतो.
  BlogNotifier({BlogService? blogService})
      : _blogService = blogService ?? BlogService(),
        super(const BlogState());

  // ── Get All Blogs ──────────────────────────────────────────────────
  // ✅ categories पण इथूनच येतात
  Future<void> getBlogs({
    String? category,
    String? search,
    int page = 1,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _blogService.getBlogs(
        category: category,
        search:   search,
        page:     page,
      );
      final data = response['data'] ?? {};
      state = state.copyWith(
        isLoading:  false,
        blogs:      data['blogs']      ?? [],
        categories: data['categories'] ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get Blog Detail ────────────────────────────────────────────────
  Future<void> getBlogDetail(String slug) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _blogService.getBlogDetail(slug);
      state = state.copyWith(
        isLoading:    false,
        selectedBlog: response['data'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Add Comment ────────────────────────────────────────────────────
  Future<bool> addComment({
    required int blogId,
    required String comment,
  }) async {
    try {
      await _blogService.addComment(blogId: blogId, comment: comment);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Toggle Like ────────────────────────────────────────────────────
  Future<bool> toggleLike(int blogId) async {
    try {
      await _blogService.toggleLike(blogId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Set Selected Category ──────────────────────────────────────────
  void setSelectedCategory(int index, {String? categoryName}) {
    state = state.copyWith(selectedCategory: index);
    if (index == 0) {
      getBlogs();
    } else if (categoryName != null) {
      getBlogs(category: categoryName);
    }
  }

  Future<void> refresh() => getBlogs();

  // ✅ FIX: तोच copyWith null-clearing bug (wishlist/product_provider मध्ये
  // सापडला होता तोच) — `null ?? this.error` जुनाच error ठेवतो, त्यामुळे आधी
  // हे function प्रत्यक्षात काहीच करत नव्हतं. State थेट rebuild करून खरंच
  // clear करतो.
  void clearError() {
    state = BlogState(
      isLoading:        state.isLoading,
      blogs:             state.blogs,
      categories:        state.categories,
      selectedBlog:      state.selectedBlog,
      selectedCategory:  state.selectedCategory,
      error:             null,
    );
  }

  // ✅ FIX: तोच bug — clearSelectedBlog पण `?? this.selectedBlog` मुळे
  // कधीच null करत नव्हतं (जुना selectedBlog कायम राहायचा). थेट rebuild.
  void clearSelectedBlog() {
    state = BlogState(
      isLoading:        state.isLoading,
      blogs:             state.blogs,
      categories:        state.categories,
      selectedBlog:      null,
      selectedCategory:  state.selectedCategory,
      error:             state.error,
    );
  }
}

final blogProvider = StateNotifierProvider<BlogNotifier, BlogState>(
      (ref) => BlogNotifier(),
);