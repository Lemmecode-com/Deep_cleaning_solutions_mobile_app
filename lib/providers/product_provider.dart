// lib/providers/product_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/product_service.dart';

// ── Product State ─────────────────────────────────────────────────────
class ProductState {
  final bool isLoading;
  final List<dynamic> products;
  final List<dynamic> furnishedFlats;
  final List<dynamic> unfurnishedFlats;
  final Map<String, dynamic>? selectedProduct;
  final List<dynamic> reviews;
  final List<dynamic> searchResults;
  final String? error;

  const ProductState({
    this.isLoading        = false,
    this.products         = const [],
    this.furnishedFlats   = const [],
    this.unfurnishedFlats = const [],
    this.selectedProduct,
    this.reviews          = const [],
    this.searchResults    = const [],
    this.error,
  });

  ProductState copyWith({
    bool? isLoading,
    List<dynamic>? products,
    List<dynamic>? furnishedFlats,
    List<dynamic>? unfurnishedFlats,
    Map<String, dynamic>? selectedProduct,
    List<dynamic>? reviews,
    List<dynamic>? searchResults,
    String? error,
  }) {
    return ProductState(
      isLoading:        isLoading        ?? this.isLoading,
      products:         products         ?? this.products,
      furnishedFlats:   furnishedFlats   ?? this.furnishedFlats,
      unfurnishedFlats: unfurnishedFlats ?? this.unfurnishedFlats,
      selectedProduct:  selectedProduct  ?? this.selectedProduct,
      reviews:          reviews          ?? this.reviews,
      searchResults:    searchResults    ?? this.searchResults,
      error:            error            ?? this.error,
    );
  }
}

// ── Product Notifier ──────────────────────────────────────────────────
class ProductNotifier extends StateNotifier<ProductState> {
  final ProductService _productService;

  // ✅ CHANGED (testability साठी): आधी `final ProductService _productService
  // = ProductService();` कायमचं fixed होतं. आता optional named parameter —
  // टेस्टमध्ये ProductNotifier(productService: mockProductService) करून
  // mock घुसवता येतो.
  ProductNotifier({ProductService? productService})
      : _productService = productService ?? ProductService(),
        super(const ProductState());

  // ── Get All Products ───────────────────────────────────────────────
  Future<void> getProducts({
    String? category,
    String? search,
    int page = 1,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _productService.getProducts(
        category: category,
        search:   search,
        page:     page,
      );
      state = state.copyWith(
        isLoading: false,
        products:  response['products'] ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get Product Detail ─────────────────────────────────────────────
  Future<void> getProductDetail(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _productService.getProductDetail(id);
      state = state.copyWith(
        isLoading:       false,
        selectedProduct: response['product'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get Furnished Flats ────────────────────────────────────────────
  Future<void> getFurnishedFlats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _productService.getFurnishedFlats();
      final flats = response['products'] ?? [];
      state = state.copyWith(
        isLoading:      false,
        furnishedFlats: flats,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get Unfurnished Flats ──────────────────────────────────────────
  Future<void> getUnfurnishedFlats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _productService.getUnfurnishedFlats();
      final flats = response['products'] ?? [];
      state = state.copyWith(
        isLoading:        false,
        unfurnishedFlats: flats,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get BHK List ───────────────────────────────────────────────────
  Future<void> getBHKList({
    required String type,
    required String bhk,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _productService.getBHKList(
        type: type,
        bhk:  bhk,
      );
      state = state.copyWith(
        isLoading: false,
        products:  response['products'] ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Search Products ────────────────────────────────────────────────
  Future<void> searchProducts(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _productService.searchProducts(query);
      state = state.copyWith(
        isLoading:     false,
        searchResults: response['products'] ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get Product Reviews ────────────────────────────────────────────
  Future<void> getProductReviews(int productId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _productService.getProductReviews(productId);
      state = state.copyWith(
        isLoading: false,
        reviews:   response['reviews'] ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Add Product Review ─────────────────────────────────────────────
  Future<bool> addProductReview({
    required int productId,
    required int rating,
    required String review,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _productService.addProductReview(
        productId: productId,
        rating:    rating,
        review:    review,
      );
      await getProductReviews(productId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Clear Error ────────────────────────────────────────────────────
  // ✅ FIX: copyWith मधला `??` pattern कधीच null clear करू शकत नाही
  // (`null ?? this.error` जुनाच value ठेवतो) — त्यामुळे आधी हे function
  // प्रत्यक्षात काहीच करत नव्हतं. State थेट rebuild करून खरंच clear करतो.
  void clearError() {
    state = ProductState(
      isLoading:        state.isLoading,
      products:         state.products,
      furnishedFlats:   state.furnishedFlats,
      unfurnishedFlats: state.unfurnishedFlats,
      selectedProduct:  state.selectedProduct,
      reviews:          state.reviews,
      searchResults:    state.searchResults,
      error:            null,
    );
  }

  // ── Clear Selected Product ─────────────────────────────────────────
  // ✅ FIX: तोच `??` clearing bug — इथेही state rebuild करून fix केलं.
  void clearSelectedProduct() {
    state = ProductState(
      isLoading:        state.isLoading,
      products:         state.products,
      furnishedFlats:   state.furnishedFlats,
      unfurnishedFlats: state.unfurnishedFlats,
      selectedProduct:  null,
      reviews:          state.reviews,
      searchResults:    state.searchResults,
      error:            state.error,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────
final productProvider = StateNotifierProvider<ProductNotifier, ProductState>(
      (ref) => ProductNotifier(),
);