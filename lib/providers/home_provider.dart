// lib/providers/home_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/home_service.dart';

// ── Home State ────────────────────────────────────────────────────────
class HomeState {
  final bool isLoading;
  final List<dynamic> banners;
  final List<dynamic> categories;
  final List<dynamic> team;
  final List<dynamic> testimonials;
  final List<dynamic> faqs;
  final List<dynamic> videos;
  final String? error;

  const HomeState({
    this.isLoading    = false,
    this.banners      = const [],
    this.categories   = const [],
    this.team         = const [],
    this.testimonials = const [],
    this.faqs         = const [],
    this.videos       = const [],
    this.error,
  });

  // ✅ FIX: `clearError` flag add केला. आधी success case मध्ये
  //    `error` parameter pass न केल्यास जुना error state तसाच
  //    राहायचा (कारण `error ?? this.error` — null आलं की जुनं
  //    value वापरायचं). त्यामुळे API call यशस्वी झाला तरी UI
  //    "No internet" error screen वरच अडकून राहायचा. आता success
  //    call वेळी `clearError: true` पाठवलं की error explicitly
  //    null होईल.
  HomeState copyWith({
    bool? isLoading,
    List<dynamic>? banners,
    List<dynamic>? categories,
    List<dynamic>? team,
    List<dynamic>? testimonials,
    List<dynamic>? faqs,
    List<dynamic>? videos,
    String? error,
    bool clearError = false,
  }) {
    return HomeState(
      isLoading:    isLoading    ?? this.isLoading,
      banners:      banners      ?? this.banners,
      categories:   categories   ?? this.categories,
      team:         team         ?? this.team,
      testimonials: testimonials ?? this.testimonials,
      faqs:         faqs         ?? this.faqs,
      videos:       videos       ?? this.videos,
      error:        clearError ? null : (error ?? this.error),
    );
  }
}

// ── Home Notifier ─────────────────────────────────────────────────────
class HomeNotifier extends StateNotifier<HomeState> {
  final HomeService _homeService;

  // ✅ CHANGED (testability साठी): आधी `final HomeService _homeService =
  // HomeService();` कायमचं fixed होतं. आता optional named parameter —
  // टेस्टमध्ये HomeNotifier(homeService: mockHomeService) करून mock
  // घुसवता येतो.
  HomeNotifier({HomeService? homeService})
      : _homeService = homeService ?? HomeService(),
        super(const HomeState()) {
    getHomeData();
  }

  // ── Get Home Data ──────────────────────────────────────────────────
  Future<void> getHomeData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _homeService.getHomeData();
      state = state.copyWith(
        isLoading:    false,
        banners:      response['banners']      ?? [],
        categories:   response['categories']   ?? [],
        team:         response['team']         ?? [],
        testimonials: response['testimonials'] ?? [],
        faqs:         response['faqs']         ?? [],
        videos:       response['videos']       ?? [],
        clearError:   true, // ✅ success झाल्यावर जुना error साफ करा
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get Banners ────────────────────────────────────────────────────
  Future<void> getBanners() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _homeService.getBanners();
      state = state.copyWith(
        isLoading:  false,
        banners:    response['banners'] ?? [],
        clearError: true, // ✅
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get Categories ─────────────────────────────────────────────────
  Future<void> getCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _homeService.getCategories();
      state = state.copyWith(
        isLoading:  false,
        categories: response['categories'] ?? [],
        clearError: true, // ✅
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get FAQs ───────────────────────────────────────────────────────
  Future<void> getFAQs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _homeService.getFAQs();
      state = state.copyWith(
        isLoading:  false,
        faqs:       response['faqs'] ?? [],
        clearError: true, // ✅
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get Videos ─────────────────────────────────────────────────────
  Future<void> getVideos() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _homeService.getVideos();
      state = state.copyWith(
        isLoading:  false,
        videos:     response['videos'] ?? [],
        clearError: true, // ✅
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Refresh ────────────────────────────────────────────────────────
  Future<void> refresh() async {
    await getHomeData();
  }

  // ── Clear Error ────────────────────────────────────────────────────
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ── Provider ──────────────────────────────────────────────────────────
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
      (ref) => HomeNotifier(),
);