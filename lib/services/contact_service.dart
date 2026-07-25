// lib/services/contact_service.dart

import 'api_client.dart';

class ContactService {
  final ApiClient _api;

  // ✅ CHANGED (testability साठी): आधी `final ApiClient _api = ApiClient();`
  // कायमचं fixed होतं. आता optional named parameter — टेस्टमध्ये
  // ContactService(apiClient: mockApiClient) करून mock घुसवता येतो.
  ContactService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  // ✅ FIX: phone → mobile, added 'service' field
  Future<Map<String, dynamic>> sendMessage({
    required String name,
    required String email,
    required String mobile,
    required String service,
    required String message,
  }) async {
    final response = await _api.post(
      '/contact',
      data: {
        'name':    name,
        'email':   email,
        'mobile':  mobile,
        'service': service,
        'message': message,
      },
    );
    return response.data;
  }

  // ✅ GET /contact
  Future<Map<String, dynamic>> getContactInfo() async {
    final response = await _api.get('/contact');
    return response.data;
  }
}