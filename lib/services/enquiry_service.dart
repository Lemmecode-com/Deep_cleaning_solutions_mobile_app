// lib/services/enquiry_service.dart

import 'api_client.dart';

class EnquiryService {
  final ApiClient _api;

  // ✅ CHANGED (testability साठी): आधी `final ApiClient _api = ApiClient();`
  // कायमचं fixed होतं. आता optional named parameter — टेस्टमध्ये
  // EnquiryService(apiClient: mockApiClient) करून mock घुसवता येतो.
  EnquiryService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  // ✅ FIX: service_type → service, removed order_inspection field
  Future<Map<String, dynamic>> submitEnquiry({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String address,
    required String state,
    required String city,
    required String service,
    String? inspectionDate,
    String? inspectionTime,
    bool orderInspection = false,
  }) async {
    final response = await _api.post(
      '/enquiry',
      data: {
        'first_name':  firstName,
        'last_name':   lastName,
        'email':       email,
        'mobile':      mobile,
        'address':     address,
        'state':       state,
        'city':        city,
        'service':     service,
        'order_inspection':  orderInspection ? 1 : 0,
        if (inspectionDate != null) 'inspection_date': inspectionDate,
        if (inspectionTime != null) 'inspection_time': inspectionTime,
      },
    );
    return response.data;
  }

  // ✅ GET /enquiry/{id}/payment-status
  Future<Map<String, dynamic>> getEnquiryPaymentStatus(int enquiryId) async {
    final response = await _api.get('/enquiry/$enquiryId/payment-status');
    return response.data;
  }
}