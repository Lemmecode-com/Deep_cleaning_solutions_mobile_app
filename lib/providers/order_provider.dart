// lib/providers/order_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_service.dart';

class OrderState {
  final bool isLoading;
  final List<dynamic> orders;
  final Map<String, dynamic>? selectedOrder;
  final Map<String, dynamic> timeSlots;
  final String? redirectUrl;
  final String? error;

  // Checkout branch + area + summary state
  final List<Map<String, dynamic>> branches; // ✅ NEW: from /checkout/init
  final int? selectedBranchId;                // ✅ NEW
  final List<Map<String, dynamic>> cityAreas;
  final int? selectedAreaId;
  final double shippingCharge;
  final double subtotal;
  final double discount;
  final String? couponCode;
  final double grandTotal;
  final double advanceAmount; // from /checkout/summary's advance_amount
  final bool isInitLoading;
  final bool isCouponLoading;
  final String? couponError;

  // ✅ NEW: set when a checkout attempt was blocked with a 403 because the
  // account has a pending DPDPA deletion request. Reset to false at the
  // start of every new processOrder/processAdvanceOrder attempt.
  final bool isDeletionBlocked;

  // Area suggested from the customer's saved address (country_id),
  // returned by /checkout/init. This is a HINT for the UI dropdown only —
  // it must never be auto-applied to shipping/grandTotal. The user has to
  // actually pick an area before any charge is calculated.
  final int? suggestedAreaId;

  const OrderState({
    this.isLoading     = false,
    this.orders        = const [],
    this.selectedOrder,
    this.timeSlots     = const {},
    this.redirectUrl,
    this.error,
    this.branches         = const [], // ✅ NEW
    this.selectedBranchId,            // ✅ NEW
    this.cityAreas       = const [],
    this.selectedAreaId,
    this.shippingCharge  = 0,
    this.subtotal        = 0,
    this.discount         = 0,
    this.couponCode,
    this.grandTotal       = 0,
    this.advanceAmount    = 0,
    this.isInitLoading    = false,
    this.isCouponLoading  = false,
    this.couponError,
    this.isDeletionBlocked = false, // ✅ NEW
    this.suggestedAreaId,
  });

  OrderState copyWith({
    bool? isLoading,
    List<dynamic>? orders,
    Map<String, dynamic>? selectedOrder,
    Map<String, dynamic>? timeSlots,
    String? redirectUrl,
    String? error,
    List<Map<String, dynamic>>? branches,
    int? selectedBranchId,
    List<Map<String, dynamic>>? cityAreas,
    int? selectedAreaId,
    double? shippingCharge,
    double? subtotal,
    double? discount,
    String? couponCode,
    double? grandTotal,
    double? advanceAmount,
    bool? isInitLoading,
    bool? isCouponLoading,
    String? couponError,
    bool? isDeletionBlocked,
    int? suggestedAreaId,
  }) {
    return OrderState(
      isLoading:     isLoading     ?? this.isLoading,
      orders:        orders        ?? this.orders,
      selectedOrder: selectedOrder ?? this.selectedOrder,
      timeSlots:     timeSlots     ?? this.timeSlots,
      redirectUrl:   redirectUrl   ?? this.redirectUrl,
      error:         error         ?? this.error,
      branches:        branches        ?? this.branches,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      cityAreas:      cityAreas      ?? this.cityAreas,
      selectedAreaId: selectedAreaId ?? this.selectedAreaId,
      shippingCharge: shippingCharge ?? this.shippingCharge,
      subtotal:       subtotal       ?? this.subtotal,
      discount:       discount       ?? this.discount,
      couponCode:     couponCode     ?? this.couponCode,
      grandTotal:     grandTotal     ?? this.grandTotal,
      advanceAmount:  advanceAmount  ?? this.advanceAmount,
      isInitLoading:   isInitLoading   ?? this.isInitLoading,
      isCouponLoading: isCouponLoading ?? this.isCouponLoading,
      couponError:     couponError     ?? this.couponError,
      // bool fields: `??` फक्त null असताना fallback करतो, त्यामुळे
      // explicit `false` पाठवल्यास व्यवस्थित override होतं — इथे कुठलीही
      // "explicit-null-clear" समस्या नाही.
      isDeletionBlocked: isDeletionBlocked ?? this.isDeletionBlocked,
      suggestedAreaId: suggestedAreaId ?? this.suggestedAreaId,
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  // ✅ FIX: backend sends amounts >= 1000 with a thousands-separator comma
  // (e.g. "6,600.00"), which double.tryParse() cannot handle and silently
  // returns null for -> was showing up as 0 in the UI (subtotal/grand_total
  // bug). Smaller amounts like "650.00" have no comma and parsed fine,
  // which is why only the larger fields looked broken. Strip commas first.
  final cleaned = v.toString().replaceAll(',', '');
  return double.tryParse(cleaned) ?? 0.0;
}

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderService _orderService = OrderService();
  OrderNotifier() : super(const OrderState());

  // ✅ NEW: guards against a race condition — if the user switches city
  // quickly, an OLDER /checkout/init request can resolve AFTER a NEWER
  // one (network timing isn't guaranteed), which would silently overwrite
  // the correct, just-fetched city_areas with the previous city's stale
  // ones. Every call gets a sequence number; only the response matching
  // the LATEST call is ever applied to state.
  int _initRequestSeq = 0;

  // ── Get All Orders ─────────────────────────────────────────────────
  Future<void> getOrders({String? status, int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _orderService.getOrders(status: status, page: page);
      state = state.copyWith(
        isLoading: false,
        orders:    (response['data']?['orders']) ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get Order Detail ───────────────────────────────────────────────
  Future<void> getOrderDetail(int orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _orderService.getOrderDetail(orderId);
      state = state.copyWith(
        isLoading:     false,
        selectedOrder: response['data'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get Payment Status ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> getPaymentStatus(int orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _orderService.getPaymentStatus(orderId);
      state = state.copyWith(isLoading: false);
      return response['data'];
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  // ── Get Time Slots ─────────────────────────────────────────────────
  Future<void> getTimeSlots({required String date}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _orderService.getTimeSlots(date: date);
      final slots = response['data']?['time_slots'];
      state = state.copyWith(
        isLoading: false,
        timeSlots: slots is Map<String, dynamic> ? slots : {},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Checkout Init (branches + area list + prefilled subtotal) ───────
  // ✅ FIX: `branch_id` आता required (server-required query param).
  // पहिल्यांदा call करताना screen कडून branchId=1 (Pune) पाठवला जातो.
  // Branch बदलल्यावर हेच function नव्या branchId सोबत पुन्हा call होतं —
  // तेव्हा त्या branch साठी शिल्लक असलेली area/pricing state (जी आधीच्या
  // branch ची होती) साफ करणं गरजेचं आहे, नाहीतर चुकीच्या area सोबत wrong
  // charge दिसू शकतो. फक्त `suggestedAreaId` (customer_address) कधीच
  // auto-apply होत नाही — तो फक्त UI hint आहे.
  Future<void> getCheckoutInit({required int branchId}) async {
    final requestSeq = ++_initRequestSeq; // ✅ NEW: this call's ticket number
    state = state.copyWith(isInitLoading: true, error: null);
    try {
      final response = await _orderService.checkoutInit(branchId: branchId);

      // ✅ NEW: a newer getCheckoutInit call was made while this one was
      // still in flight — its response (once it arrives) will be the
      // authoritative one, so drop this stale one instead of applying it.
      if (requestSeq != _initRequestSeq) return;

      final data = response['data'] ?? {};

      final branchesList = (data['branches'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final areas = (data['city_areas'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      int? preselected;
      final custAddr = data['customer_address'];
      if (custAddr != null && custAddr['country_id'] != null) {
        final raw = custAddr['country_id'];
        preselected = raw is int ? raw : int.tryParse(raw.toString());
      }

      final respBranchIdRaw = data['branch_id'];
      final respBranchId = respBranchIdRaw is int
          ? respBranchIdRaw
          : int.tryParse(respBranchIdRaw?.toString() ?? '') ?? branchId;

      // Only reset area/pricing when we're actually switching AWAY from a
      // previously-loaded branch — first load (selectedBranchId == null)
      // has nothing to reset anyway.
      final branchChanged = state.selectedBranchId != null &&
          state.selectedBranchId != respBranchId;

      state = OrderState(
        isLoading:      state.isLoading,
        orders:         state.orders,
        selectedOrder:  state.selectedOrder,
        timeSlots:      branchChanged ? const {} : state.timeSlots,
        redirectUrl:    state.redirectUrl,
        error:          null,
        branches:        branchesList,
        selectedBranchId: respBranchId,
        cityAreas:       areas,
        selectedAreaId:  branchChanged ? null : state.selectedAreaId,
        shippingCharge:  branchChanged ? 0 : state.shippingCharge,
        subtotal:        _toDouble(data['subtotal']),
        discount:        branchChanged ? 0 : state.discount,
        couponCode:      branchChanged ? null : state.couponCode,
        grandTotal:      branchChanged ? 0 : state.grandTotal,
        advanceAmount:   branchChanged ? 0 : state.advanceAmount,
        isInitLoading:   false,
        isCouponLoading: false,
        couponError:     null,
        isDeletionBlocked: state.isDeletionBlocked,
        suggestedAreaId: preselected,
      );
    } catch (e) {
      if (requestSeq != _initRequestSeq) return; // ✅ NEW: stale error, ignore
      state = state.copyWith(isInitLoading: false, error: e.toString());
    }
  }

  // ── User picks an area → fetch live shipping/discount/total ─────────
  Future<void> selectArea(int areaId) async {
    state = state.copyWith(selectedAreaId: areaId, isInitLoading: true);
    try {
      final response = await _orderService.checkoutSummary(countryId: areaId);
      _applySummary(response['data'] ?? {});
    } catch (e) {
      state = state.copyWith(isInitLoading: false, error: e.toString());
    }
  }

  // ── Apply Coupon ─────────────────────────────────────────────────
  // ✅ FIX: now passes the already-selected area's id as country_id so
  // the backend doesn't drop shipping_charge to 0 when applying a coupon.
  Future<bool> applyCoupon(String code) async {
    // ✅ NOTE: copyWith's `??` pattern can't clear a String? field to null,
    // so we rebuild OrderState directly here to actually clear a stale
    // couponError from a previous failed attempt.
    state = OrderState(
      isLoading: state.isLoading, orders: state.orders, selectedOrder: state.selectedOrder,
      timeSlots: state.timeSlots, redirectUrl: state.redirectUrl, error: state.error,
      branches: state.branches, selectedBranchId: state.selectedBranchId,
      cityAreas: state.cityAreas, selectedAreaId: state.selectedAreaId,
      shippingCharge: state.shippingCharge, subtotal: state.subtotal, discount: state.discount,
      couponCode: state.couponCode, grandTotal: state.grandTotal, advanceAmount: state.advanceAmount,
      isInitLoading: state.isInitLoading, isCouponLoading: true, couponError: null,
      isDeletionBlocked: state.isDeletionBlocked,
      suggestedAreaId: state.suggestedAreaId,
    );
    try {
      final response = await _orderService.applyCoupon(
        code: code,
        countryId: state.selectedAreaId,
      );
      _applySummary(response['data'] ?? {}, couponLoadingDone: true);
      return true;
    } catch (e) {
      state = OrderState(
        isLoading: state.isLoading, orders: state.orders, selectedOrder: state.selectedOrder,
        timeSlots: state.timeSlots, redirectUrl: state.redirectUrl, error: state.error,
        branches: state.branches, selectedBranchId: state.selectedBranchId,
        cityAreas: state.cityAreas, selectedAreaId: state.selectedAreaId,
        shippingCharge: state.shippingCharge, subtotal: state.subtotal, discount: state.discount,
        couponCode: state.couponCode, grandTotal: state.grandTotal, advanceAmount: state.advanceAmount,
        isInitLoading: state.isInitLoading, isCouponLoading: false,
        couponError: 'Invalid or expired coupon code',
        isDeletionBlocked: state.isDeletionBlocked,
        suggestedAreaId: state.suggestedAreaId,
      );
      return false;
    }
  }

  // ── Remove Coupon ────────────────────────────────────────────────
  // ✅ FIX: same as applyCoupon — pass the selected area's id along.
  Future<void> removeCoupon() async {
    state = state.copyWith(isCouponLoading: true);
    try {
      final response = await _orderService.removeCoupon(
        countryId: state.selectedAreaId,
      );
      _applySummary(response['data'] ?? {}, couponLoadingDone: true);
    } catch (e) {
      state = state.copyWith(isCouponLoading: false, error: e.toString());
    }
  }

  // ── shared helper: apply a /checkout/summary-shaped response ────────
  void _applySummary(Map<String, dynamic> data, {bool couponLoadingDone = false}) {
    state = OrderState(
      isLoading: state.isLoading, orders: state.orders, selectedOrder: state.selectedOrder,
      timeSlots: state.timeSlots, redirectUrl: state.redirectUrl, error: null,
      branches: state.branches, selectedBranchId: state.selectedBranchId,
      cityAreas: state.cityAreas, selectedAreaId: state.selectedAreaId,
      shippingCharge: _toDouble(data['shipping_charge']),
      subtotal:       _toDouble(data['subtotal']),
      discount:       _toDouble(data['discount']),
      couponCode:     data['coupon_code']?.toString(),
      grandTotal:     _toDouble(data['grand_total']),
      advanceAmount:  _toDouble(data['advance_amount']),
      isInitLoading:   false,
      isCouponLoading: couponLoadingDone ? false : state.isCouponLoading,
      couponError:     null,
      isDeletionBlocked: state.isDeletionBlocked,
      suggestedAreaId: state.suggestedAreaId,
    );
  }

  // ── Process Order (Full Payment) ───────────────────────────────────
  Future<bool> processOrder({
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
    // ✅ reset isDeletionBlocked at the start of every new attempt
    state = state.copyWith(isLoading: true, error: null, isDeletionBlocked: false);
    try {
      final response = await _orderService.processOrder(
        firstName:   firstName,
        lastName:    lastName,
        email:       email,
        branchId:    branchId,
        country:     country,
        apartment:   apartment,
        address:     address,
        city:        city,
        zip:         zip,
        mobile:      mobile,
        bookingDate: bookingDate,
        bookingTime: bookingTime,
        orderNotes:  orderNotes,
      );
      final data = response['data'];
      state = state.copyWith(
        isLoading:    false,
        selectedOrder: data,
        redirectUrl:  data?['redirect_url'],
      );
      await getOrders();
      return true;
    } on AccountDeletionPendingException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message, isDeletionBlocked: true);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Process Advance Order (Advance Payment) ────────────────────────
  Future<bool> processAdvanceOrder({
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
    // ✅ reset isDeletionBlocked at the start of every new attempt
    state = state.copyWith(isLoading: true, error: null, isDeletionBlocked: false);
    try {
      final response = await _orderService.processAdvanceOrder(
        firstName:   firstName,
        lastName:    lastName,
        email:       email,
        branchId:    branchId,
        country:     country,
        apartment:   apartment,
        address:     address,
        city:        city,
        zip:         zip,
        mobile:      mobile,
        bookingDate: bookingDate,
        bookingTime: bookingTime,
        orderNotes:  orderNotes,
      );
      final data = response['data'];
      state = state.copyWith(
        isLoading:     false,
        selectedOrder: data,
        redirectUrl:   data?['redirect_url'],
      );
      await getOrders();
      return true;
    } on AccountDeletionPendingException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message, isDeletionBlocked: true);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void addOrder(Map<String, dynamic> order) {
    final updated = [...state.orders];
    updated.insert(0, order);
    state = state.copyWith(orders: updated);
  }

  void clearSelectedOrder() => state = state.copyWith(selectedOrder: null);
  void clearRedirectUrl()   => state = state.copyWith(redirectUrl: null);
  void clearError()         => state = state.copyWith(error: null);
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>(
      (ref) => OrderNotifier(),
);