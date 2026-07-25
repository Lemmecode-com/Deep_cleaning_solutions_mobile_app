// lib/services/home_service.dart

import 'api_client.dart';

class HomeService {
  final ApiClient _api;

  // ✅ CHANGED (testability साठी): आधी `final ApiClient _api = ApiClient();`
  // कायमचं fixed होतं. आता optional named parameter — टेस्टमध्ये
  // HomeService(apiClient: mockApiClient) करून mock घुसवता येतो.
  HomeService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  // ── Get Home Data ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getHomeData() async {
    final response = await _api.get('/home');
    return response.data;
  }

  // ── Get Categories ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getCategories() async {
    final response = await _api.get('/categories');
    return response.data;
  }

  // ── Get Banners ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getBanners() async {
    final response = await _api.get('/home/banners');
    return response.data;
  }

  // ── Get Team ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getTeam() async {
    final response = await _api.get('/home/team');
    return response.data;
  }

  // ── Get Testimonials ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getTestimonials() async {
    final response = await _api.get('/home/testimonials');
    return response.data;
  }

  // ── Get FAQs ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getFAQs() async {
    final response = await _api.get('/home/faqs');
    return response.data;
  }

  // ── Get Videos ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getVideos() async {
    final response = await _api.get('/home/videos');
    return response.data;
  }
}