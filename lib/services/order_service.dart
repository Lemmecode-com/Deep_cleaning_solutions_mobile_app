// lib/services/order_service.dart

import 'api_client.dart';

// ✅ NEW: DPDPA grace-period मध्ये असताना checkout/enquiry केल्यास backend
// 403 देतो ("attempting to place an order or submit an enquiry returns a
// 403"). हा specific exception वापरून order_provider/checkout_screen ला
// normal errors पेक्षा वेगळं, dedicated UI (Cancel Deletion shortcut सह)
// दाखवता येतं — नुसतं message-string match करण्यापेक्षा जास्त robust.
class AccountDeletionPendingException implements Exception {
  final String message;
  AccountDeletionPendingException(this.message);

  @override
  String toString() => message;
}

class OrderService {
  final ApiClient _api = ApiClient();

  // ✅ GET /orders
  Future<Map<String, dynamic>> getOrders({
    String? status,
    int page = 1,
  }) async {
    final response = await _api.get(
      '/orders',
      queryParams: {
        if (status != null) 'status': status,
        'page': page,
      },
    );
    return response.data;
  }

  // ✅ GET /orders/{orderId}
  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    final response = await _api.get('/orders/$orderId');
    return response.data;
  }

  // ✅ GET /orders/{orderId}/payment-status
  Future<Map<String, dynamic>> getPaymentStatus(int orderId) async {
    final response = await _api.get('/orders/$orderId/payment-status');
    return response.data;
  }

  // ✅ FIX: checkout/init ला आता `branch_id` (required query param) लागतो —
  // branch नुसार city_areas + state वेगळे असतात, त्यामुळे branch न देता
  // कधीही call करायचा नाही (server 422 देतो).
  Future<Map<String, dynamic>> checkoutInit({required int branchId}) async {
    final response = await _api.get(
      '/checkout/init',
      queryParams: {'branch_id': branchId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getTimeSlots({
    required String date,
  }) async {
    final response = await _api.post(
      '/checkout/time-slots',
      data: {
        'date': date,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> checkoutSummary({
    required int countryId,
  }) async {
    final response = await _api.post(
      '/checkout/summary',
      data: {
        'country_id': countryId,
      },
    );
    return response.data;
  }

  // ✅ FIX: आधी फक्त `code` पाठवला जात होता, त्यामुळे backend ला निवडलेलं
  // area कळायचं नाही आणि shipping_charge 0 यायचा. आता `country_id` पण
  // पाठवतो (available असेल तर).
  Future<Map<String, dynamic>> applyCoupon({
    required String code,
    int? countryId, // ✅ NEW
  }) async {
    final response = await _api.post(
      '/checkout/apply-coupon',
      data: {
        'code': code,
        if (countryId != null) 'country_id': countryId, // ✅ NEW
      },
    );
    return response.data;
  }

  // ✅ FIX: तोच context remove-coupon ला पण पाठवतो
  Future<Map<String, dynamic>> removeCoupon({int? countryId}) async {
    final response = await _api.post(
      '/checkout/remove-coupon',
      data: {
        if (countryId != null) 'country_id': countryId, // ✅ NEW
      },
    );
    return response.data;
  }

  // ── Process Order (Full Payment) ───────────────────────────────────
  // ✅ FIX: `branch_id` add केला (server ला हवा — country/area त्याच
  // branch चा असावा लागतो, नाहीतर 422). `state` पूर्ण काढला — API doc
  // नुसार server तो नेहमी `branch_id` वरून derive करतो आणि पाठवलेली
  // कोणतीही value ignore करतो, त्यामुळे पाठवण्यात अर्थ नाही.
  Future<Map<String, dynamic>> processOrder({
    required String firstName,
    required String lastName,
    required String email,
    required int branchId, // ✅ NEW
    required int country,
    String? apartment,
    required String address,
    required String city,
    required String zip,
    required String mobile,
    required String bookingDate,
    required String bookingTime,
    String? orderNotes,
  }) async {
    try {
      final response = await _api.post(
        '/checkout/process',
        data: {
          'first_name':   firstName,
          'last_name':    lastName,
          'email':        email,
          'branch_id':    branchId, // ✅ NEW
          'country':      country,
          if (apartment != null && apartment.isNotEmpty) 'apartment': apartment,
          'address':      address,
          'city':         city,
          'zip':          zip,
          'mobile':       mobile,
          'booking_date': bookingDate,
          'booking_time': bookingTime,
          if (orderNotes != null && orderNotes.isNotEmpty) 'order_notes': orderNotes,
        },
      );
      return response.data;
    } on ApiException catch (e) {
      // ✅ NEW: grace-period मध्ये असताना order block होतो — 403
      if (e.statusCode == 403) throw AccountDeletionPendingException(e.message);
      rethrow;
    }
  }

  // ── Process Advance Order (Advance Payment) ────────────────────────
  Future<Map<String, dynamic>> processAdvanceOrder({
    required String firstName,
    required String lastName,
    required String email,
    required int branchId, // ✅ NEW
    required int country,
    String? apartment,
    required String address,
    required String city,
    required String zip,
    required String mobile,
    required String bookingDate,
    required String bookingTime,
    String? orderNotes,
  }) async {
    try {
      final response = await _api.post(
        '/checkout/process-advance',
        data: {
          'first_name':   firstName,
          'last_name':    lastName,
          'email':        email,
          'branch_id':    branchId, // ✅ NEW
          'country':      country,
          if (apartment != null && apartment.isNotEmpty) 'apartment': apartment,
          'address':      address,
          'city':         city,
          'zip':          zip,
          'mobile':       mobile,
          'booking_date': bookingDate,
          'booking_time': bookingTime,
          if (orderNotes != null && orderNotes.isNotEmpty) 'order_notes': orderNotes,
        },
      );
      return response.data;
    } on ApiException catch (e) {
      // ✅ NEW: grace-period मध्ये असताना order block होतो — 403
      if (e.statusCode == 403) throw AccountDeletionPendingException(e.message);
      rethrow;
    }
  }
}