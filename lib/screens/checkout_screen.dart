// lib/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/providers/cart_provider.dart';
import 'package:dcs_app/providers/order_provider.dart';
import 'package:dcs_app/providers/auth_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _firstNameCtrl   = TextEditingController();
  final _lastNameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _mobileCtrl      = TextEditingController();

  // Single _addressCtrl replaced with the 4 fields the website has
  // (Flat/Bungalow No., Wing, Society/Property Name, Landmark). Combined
  // into `apartment` (flat+wing) and `address` (society+landmark) before
  // hitting the API — see _buildApartmentAndAddress() below.
  final _flatCtrl        = TextEditingController(); // Flat / Bungalow No. *
  final _wingCtrl        = TextEditingController(); // Wing (optional)
  final _societyCtrl     = TextEditingController(); // Society / Property Name *
  final _landmarkCtrl    = TextEditingController(); // Landmark (optional)

  // ✅ FIX: city/state text fields removed entirely. Per the API doc,
  // city comes from the selected branch (`branches[].city`) and state is
  // ALWAYS server-derived from branch_id — sending either as free text was
  // wrong (and state is silently ignored by the server anyway).
  final _zipCtrl         = TextEditingController();
  final _couponCtrl      = TextEditingController();
  final _notesCtrl       = TextEditingController();

  // ✅ FIX: no default city pre-selected. Doc says the FIRST API call
  // must pass branch_id=1 (Pune) just to populate the branches dropdown
  // list — but that's purely a backend requirement, not a UI default.
  // The dropdown itself starts empty ("Select your city") and the user
  // must actively pick one; the area dropdown only appears after that.
  int? _selectedBranchId;

  // Area (city_area) selected from GET /checkout/init → city_areas
  // No default — user must pick a valid area id, server rejects unknown ids with 422.
  int? _selectedAreaId;

  String? _selectedDate;
  String? _selectedTime;
  bool _isAdvancePayment = false;
  bool _isPlacingOrder   = false;

  // ✅ NEW: instead of guessing the bottom bar's height with a hardcoded
  // spacer, we measure the ACTUAL rendered height of the bottomSheet each
  // frame and size the body's trailing spacer to match exactly (+ a small
  // buffer). This guarantees the last form field is never hidden behind
  // the bottom bar, no matter how its content changes (summary row
  // showing/hiding, text wrapping on smaller screens, etc).
  final GlobalKey _bottomBarKey = GlobalKey();
  double _bottomBarHeight = 160; // sensible initial guess before first measurement

  void _measureBottomBar() {
    final ctx = _bottomBarKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final measured = box.size.height;
    if ((measured - _bottomBarHeight).abs() > 0.5) {
      // Only rebuild when it actually changed, to avoid an infinite loop.
      setState(() => _bottomBarHeight = measured);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null) {
        final name = (user['name'] ?? '').toString().split(' ');
        _firstNameCtrl.text = name.isNotEmpty ? name[0] : '';
        _lastNameCtrl.text  = name.length > 1 ? name.sublist(1).join(' ') : '';
        _emailCtrl.text     = (user['email']  ?? '').toString();
        _mobileCtrl.text    = (user['mobile'] ?? user['phone'] ?? '').toString();
      }
      // ✅ FIX: branch_id=1 sent here only because the API requires SOME
      // branch_id to return the `branches` list + prefill subtotal — it
      // does NOT pre-select a city in the UI (see _selectedBranchId above).
      ref.read(orderProvider.notifier).getCheckoutInit(branchId: 1);
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _flatCtrl.dispose();
    _wingCtrl.dispose();
    _societyCtrl.dispose();
    _landmarkCtrl.dispose();
    _zipCtrl.dispose();
    _couponCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // Combine the 4 address fields into the 2 the API expects, matching how
  // the website's fields map onto `apartment` / `address`.
  ({String apartment, String address}) _buildApartmentAndAddress() {
    final apartment = [_flatCtrl.text.trim(), _wingCtrl.text.trim()]
        .where((s) => s.isNotEmpty)
        .join(', ');
    final address = [_societyCtrl.text.trim(), _landmarkCtrl.text.trim()]
        .where((s) => s.isNotEmpty)
        .join(', ');
    return (apartment: apartment, address: address);
  }

  // ✅ NEW: looks up the city name string for the currently selected
  // branch (`branches[].city`) — this is what gets sent as `city` to
  // /checkout/process(-advance). Never hardcoded.
  String _selectedBranchCity(OrderState orderState) {
    final match = orderState.branches.firstWhere(
          (b) => b['id'] == _selectedBranchId,
      orElse: () => const {},
    );
    return match['city']?.toString() ?? '';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      // today should not be a bookable date — booking must start
      // from tomorrow onwards.
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now().add(const Duration(days: 1)),
      lastDate:    DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        // Reset previously selected time slot since it belonged to the old date
        _selectedTime = null;
      });
      if (mounted) {
        ref.read(orderProvider.notifier).getTimeSlots(date: _selectedDate!);
      }
    }
  }

  // ✅ NEW: switching branch (city) changes the whole area list + state,
  // so the previously-picked area is no longer valid — reset it and
  // re-fetch /checkout/init for the new branch.
  void _onBranchChanged(int? branchId) {
    if (branchId == null || branchId == _selectedBranchId) return;
    setState(() {
      _selectedBranchId = branchId;
      _selectedAreaId   = null;
    });
    ref.read(orderProvider.notifier).getCheckoutInit(branchId: branchId);
  }

  void _onAreaChanged(int? areaId) {
    if (areaId == null) return;
    setState(() => _selectedAreaId = areaId);
    ref.read(orderProvider.notifier).selectArea(areaId);
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(orderProvider.notifier).applyCoupon(code);
    if (ok) {
      _couponCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon applied successfully'), backgroundColor: AppColors.green),
        );
      }
    }
  }

  Future<void> _removeCoupon() async {
    await ref.read(orderProvider.notifier).removeCoupon();
  }

  // ✅ NEW: shown when a checkout attempt is blocked with a 403 because
  // the account has a pending DPDPA deletion request. Surfaces the exact
  // backend message and offers a one-tap "Cancel Deletion" shortcut.
  Future<void> _showDeletionBlockedDialog(String message) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Account Deletion Pending', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final cancelled = await ref.read(authProvider.notifier).cancelAccountDeletion();
              if (!mounted) return;
              if (cancelled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Deletion request cancelled. You can now place your order.'),
                    backgroundColor: AppColors.green,
                  ),
                );
              } else {
                final err = ref.read(authProvider).error ?? 'Could not cancel deletion request';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: AppColors.secondary),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel Deletion Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your city'), backgroundColor: AppColors.secondary),
      );
      return;
    }
    if (_selectedAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your service area'), backgroundColor: AppColors.secondary),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select booking date'), backgroundColor: AppColors.secondary),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select booking time'), backgroundColor: AppColors.secondary),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      bool success = false;

      // combine the 4 address fields before sending
      final addr = _buildApartmentAndAddress();
      final cityName = _selectedBranchCity(ref.read(orderProvider));

      if (_isAdvancePayment) {
        success = await ref.read(orderProvider.notifier).processAdvanceOrder(
          firstName:   _firstNameCtrl.text.trim(),
          lastName:    _lastNameCtrl.text.trim(),
          email:       _emailCtrl.text.trim(),
          branchId:    _selectedBranchId!,
          country:     _selectedAreaId!,
          apartment:   addr.apartment,
          address:     addr.address,
          city:        cityName,
          zip:         _zipCtrl.text.trim(),
          mobile:      _mobileCtrl.text.trim(),
          bookingDate: _selectedDate!,
          bookingTime: _selectedTime!,
          orderNotes:  _notesCtrl.text.trim(),
        );
      } else {
        success = await ref.read(orderProvider.notifier).processOrder(
          firstName:   _firstNameCtrl.text.trim(),
          lastName:    _lastNameCtrl.text.trim(),
          email:       _emailCtrl.text.trim(),
          branchId:    _selectedBranchId!,
          country:     _selectedAreaId!,
          apartment:   addr.apartment,
          address:     addr.address,
          city:        cityName,
          zip:         _zipCtrl.text.trim(),
          mobile:      _mobileCtrl.text.trim(),
          bookingDate: _selectedDate!,
          bookingTime: _selectedTime!,
          orderNotes:  _notesCtrl.text.trim(),
        );
      }

      if (success) {
        ref.read(cartProvider.notifier).clearCart();

        final redirectUrl = ref.read(orderProvider).redirectUrl;
        if (redirectUrl != null && redirectUrl.isNotEmpty) {
          final uri = Uri.parse(redirectUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully!'),
              backgroundColor: AppColors.green,
            ),
          );
          context.go('/orders');
        }
      } else if (mounted) {
        // ✅ NEW: account-deletion-pending gets its own dialog with a
        // "Cancel Deletion" shortcut instead of a plain snackbar.
        final orderState = ref.read(orderProvider);
        if (orderState.isDeletionBlocked) {
          await _showDeletionBlockedDialog(
            orderState.error ??
                'Your account is scheduled for deletion, so new orders are '
                    'temporarily blocked. Cancel your deletion request to continue.',
          );
        } else {
          final error = orderState.error ?? 'Order failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.secondary),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  // ✅ NEW: opens the full order-summary breakdown (cart items, subtotal,
  // discount, shipping, both payment options) as a draggable modal instead
  // of a permanently-visible tall bottomSheet. This is what removes the
  // overlap with the checkout form — the persistent bottom bar is now a
  // fixed, small height, and the detailed breakdown only appears on demand.
  void _showOrderSummarySheet(CartState cartState, OrderState orderState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        if (cartState.cartItems.isNotEmpty) ...[
                          ...cartState.cartItems.map((item) => _CartLineItem(item: item)),
                          const SizedBox(height: 6),
                          const Divider(height: 16),
                        ],
                        _AmountRow('Subtotal', orderState.subtotal),
                        if (orderState.discount > 0)
                          _AmountRow('Discount', -orderState.discount, color: AppColors.green),
                        _AmountRow('Commuting Charge', orderState.shippingCharge),
                        const Divider(height: 16),
                        _AmountRow(
                          'Full Payment',
                          orderState.grandTotal,
                          bold: true,
                          highlighted: !_isAdvancePayment,
                        ),
                        const SizedBox(height: 4),
                        _AmountRow(
                          'Advance Payment',
                          orderState.advanceAmount,
                          color: AppColors.green,
                          bold: true,
                          highlighted: _isAdvancePayment,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState  = ref.watch(cartProvider);
    final orderState = ref.watch(orderProvider);

    if (cartState.cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/cart'),
          ),
          title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Your cart is empty')),
      );
    }

    // Summary breakdown (subtotal/commuting charge/total) should only
    // reflect server values once the USER has actually picked an area from
    // the dropdown (_selectedAreaId).
    final hasSummary = _selectedAreaId != null &&
        (orderState.grandTotal > 0 || orderState.selectedAreaId == _selectedAreaId);

    // Switches to advanceAmount when "Advance Payment" is selected instead
    // of always showing the full grandTotal.
    final displayTotal = hasSummary
        ? (_isAdvancePayment ? orderState.advanceAmount : orderState.grandTotal)
        : cartState.finalAmount;

    // Re-measure the bottom bar after this frame paints — covers the case
    // where `hasSummary` flips (adds/removes the "View order summary" row)
    // or the total's digit count changes text height, keeping the spacer
    // in the scroll body always in sync with the real bar height.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBottomBar());

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/cart'),
        ),
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          // Re-fetches branches, city_areas, time slots (if a date is picked),
          // and cart/subtotal state — same data the screen loads on initState.
          await ref.read(orderProvider.notifier).getCheckoutInit(branchId: _selectedBranchId ?? 1);
          if (_selectedDate != null) {
            await ref.read(orderProvider.notifier).getTimeSlots(date: _selectedDate!);
          }
        },
        child: SingleChildScrollView(
          // AlwaysScrollableScrollPhysics ensures pull-to-refresh works
          // even when content is shorter than the screen (not enough to
          // scroll on its own).
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Personal Details ─────────────────
                _SectionTitle('Personal Details'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildField(_firstNameCtrl, 'First Name', validator: (v) => v!.isEmpty ? 'Required' : null)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField(_lastNameCtrl, 'Last Name',   validator: (v) => v!.isEmpty ? 'Required' : null)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildField(_emailCtrl,  'Email',        keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 10),
                _buildField(_mobileCtrl, 'Mobile Number', keyboardType: TextInputType.phone,       validator: (v) => v!.length != 10 ? '10 digits required' : null),

                const SizedBox(height: 20),

                // ── Service Location ─────────────────
                _SectionTitle('Service Location'),
                const SizedBox(height: 10),

                // ✅ NEW: Branch (city) dropdown — from /checkout/init →
                // branches. Picking a branch reloads the area dropdown
                // below for that city, and its `state` is what the server
                // uses (never sent by the app).
                _buildBranchDropdown(orderState),
                const SizedBox(height: 10),

                // ✅ FIX: area dropdown (city_areas from /checkout/init,
                // scoped to the currently selected branch) only appears
                // once the user has actually picked a city — no default
                // area/city selection.
                if (_selectedBranchId != null) ...[
                  _buildAreaDropdown(orderState),
                  const SizedBox(height: 10),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.textMuted, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Select your city first to see available areas',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Website's 4 fields (Flat/Bungalow No., Wing, Society/
                // Property Name, Landmark) instead of a single "Full Address".
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        _flatCtrl,
                        'Flat / Bungalow No.',
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(_wingCtrl, 'Wing (optional)'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildField(
                  _societyCtrl,
                  'Society / Property Name',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                _buildField(_landmarkCtrl, 'Landmark (optional)'),
                const SizedBox(height: 10),
                // ✅ FIX: city/state text fields removed — city now comes
                // from the branch dropdown above, state is server-derived.
                // Only the PIN code remains as a manual field.
                _buildField(_zipCtrl, 'PIN Code', keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : (v.length != 6 ? '6 digits required' : null)),

                const SizedBox(height: 20),

                // ── Order Notes (optional) ────
                Row(
                  children: [
                    _SectionTitle('Order Notes'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('optional', style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  maxLength: 200,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Notes about your order, e.g. special notes for delivery.',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.all(14),
                    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _QuickNoteChip(label: 'Specific areas to focus on', controller: _notesCtrl),
                    _QuickNoteChip(label: 'Call on arrival', controller: _notesCtrl),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Booking Date ─────────────────────
                _SectionTitle('Booking Schedule'),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _selectedDate ?? 'Select Booking Date',
                          style: TextStyle(
                            color: _selectedDate != null ? AppColors.black : AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Time Slots ───────────────────────
                if (_selectedDate != null) ...[
                  const SizedBox(height: 12),
                  if (orderState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (orderState.timeSlots.isNotEmpty) ...[
                    const Text('Select Time Slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: orderState.timeSlots.entries.map((entry) {
                        final key   = entry.key;
                        final label = entry.value is Map ? (entry.value['label'] ?? key) : key;
                        final time  = entry.value is Map ? (entry.value['time'] ?? key) : key;
                        final isSelected = _selectedTime == key;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTime = key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Text(label.toString(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textMuted)),
                                Text(time.toString(),  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.black)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.secondary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'No time slots available for this date',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Please select another date',
                                  style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _selectDate,
                            child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                ],

                const SizedBox(height: 20),

                // ── Coupon Code ───────────────
                _SectionTitle('Coupon Code'),
                const SizedBox(height: 10),
                _buildCouponSection(orderState),

                const SizedBox(height: 20),

                // ── Payment Type ─────────────────────
                _SectionTitle('Payment Type'),
                const SizedBox(height: 10),
                _PaymentOption(
                  label:      'Full Payment',
                  subtitle:   'Pay complete amount now',
                  value:      false,
                  groupValue: _isAdvancePayment,
                  onChanged:  (v) => setState(() => _isAdvancePayment = v),
                ),
                const SizedBox(height: 8),
                _PaymentOption(
                  label:      'Advance Payment',
                  subtitle:   'Pay 10% advance, rest on service day',
                  value:      true,
                  groupValue: _isAdvancePayment,
                  onChanged:  (v) => setState(() => _isAdvancePayment = v),
                ),

                // ✅ FIX: spacer now matches the bottom bar's REAL measured
                // height (+16px buffer) instead of a hardcoded guess. This is
                // what guarantees the checkout content never sits underneath
                // the summary bottom bar, in any state.
                SizedBox(height: _bottomBarHeight + 16),
              ],
            ),
          ),
        ),
      ),
      // ✅ FIX: replaced the tall, content-dependent bottomSheet (up to 55%
      // of screen height) with a compact fixed-height bar. Full breakdown
      // (cart items, subtotal, discount, shipping, both payment rows) now
      // lives in a draggable modal opened via "View order summary", so it
      // never permanently overlaps the checkout form.
      bottomSheet: Container(
        key: _bottomBarKey, // measured in a post-frame callback below
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasSummary) ...[
                InkWell(
                  onTap: () => _showOrderSummarySheet(cartState, orderState),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.receipt_long, size: 15, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'View order summary',
                            style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Icon(Icons.keyboard_arrow_up, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(color: AppColors.textMuted)),
                  Text(
                    '₹${displayTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isPlacingOrder
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Place Order', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Branch (city) dropdown widget — from GET /checkout/init →
  // branches. Each branch already carries its `state`, so the app never
  // needs (or shows) a separate state field.
  Widget _buildBranchDropdown(OrderState orderState) {
    if (orderState.isInitLoading && orderState.branches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<int>(
          value: _selectedBranchId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          hint: const Text('Select your city', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          style: const TextStyle(fontSize: 13, color: AppColors.black),
          items: orderState.branches.map((branch) {
            final id    = branch['id'] as int;
            final city  = branch['city']?.toString() ?? '';
            final state = branch['state']?.toString() ?? '';
            return DropdownMenuItem<int>(
              value: id,
              child: Text(state.isNotEmpty ? '$city, $state' : city),
            );
          }).toList(),
          onChanged: _onBranchChanged,
          validator: (v) => v == null ? 'Please select your city' : null,
        ),
      ),
    );
  }

  // Area dropdown widget — only show areas that actually have a rate (shipping_charge > 0)
  Widget _buildAreaDropdown(OrderState orderState) {
    if (orderState.isInitLoading && orderState.cityAreas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final ratedAreas = orderState.cityAreas.where((area) {
      final charge = area['shipping_charge'];
      return charge != null && charge is num && charge > 0;
    }).toList();

    return Container(
      // ✅ FIX: forces Flutter to build a BRAND NEW dropdown widget whenever
      // the branch changes, instead of patching/reusing the previous one.
      // Without this key, DropdownButtonFormField can keep its internal
      // popup-menu items cached from before the branch switch — tapping the
      // small arrow icon happened to rebuild it correctly, but tapping the
      // rest of the field could still open the stale, old-city menu.
      key: ValueKey('area_dropdown_${_selectedBranchId ?? 'none'}'),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<int>(
          value: _selectedAreaId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          hint: const Text('Select your area', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          style: const TextStyle(fontSize: 13, color: AppColors.black),
          items: ratedAreas.map((area) {
            final id     = area['id'] as int;
            final name   = area['name']?.toString() ?? '';
            final charge = area['shipping_charge'] as num;
            return DropdownMenuItem<int>(
              value: id,
              child: Text('$name  (+₹${charge.toStringAsFixed(0)})'),
            );
          }).toList(),
          onChanged: _onAreaChanged,
          validator: (v) => v == null ? 'Please select your area' : null,
        ),
      ),
    );
  }

  // Coupon apply/remove widget
  Widget _buildCouponSection(OrderState orderState) {
    final applied = orderState.couponCode != null && orderState.couponCode!.isNotEmpty;

    if (applied) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.green),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer, color: AppColors.green, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"${orderState.couponCode}" applied',
                style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: orderState.isCouponLoading ? null : _removeCoupon,
              child: orderState.isCouponLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Remove', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: orderState.isCouponLoading ? null : _applyCoupon,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: orderState.isCouponLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        if (orderState.couponError != null) ...[
          const SizedBox(height: 6),
          Text(
            orderState.couponError!,
            style: const TextStyle(color: AppColors.secondary, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildField(
      TextEditingController ctrl,
      String hint, {
        int maxLines = 1,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller:   ctrl,
      maxLines:     maxLines,
      keyboardType: keyboardType,
      validator:    validator,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.secondary)),
      ),
    );
  }
}

// quick-fill chip for Order Notes
class _QuickNoteChip extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _QuickNoteChip({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final current = controller.text.trim();
        controller.text = current.isEmpty ? label : '$current, $label';
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.black),
    );
  }
}

// Renders one cart item's name (+ sqft/qty if present) and price — used
// both in the modal summary sheet and could be reused elsewhere.
class _CartLineItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CartLineItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final name  = (item['name'] ?? item['service_name'] ?? '').toString();
    final price = item['price'];
    final qty   = item['quantity'] ?? item['qty'] ?? 1;
    final options = item['options'];
    final sqft = (options is Map) ? options['sqft'] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                if (sqft != null || (qty is num && qty > 1)) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (sqft != null) '$sqft sq.ft.',
                      if (qty is num && qty > 1) 'Qty: $qty',
                    ].join(' • '),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (price != null)
            Text(
              '₹${price.toString()}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.black),
            ),
        ],
      ),
    );
  }
}

// `bold` and `highlighted` let the Full Payment / Advance Payment rows be
// shown together with the selected one emphasized, matching the website's
// order summary card.
class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;
  final bool bold;
  final bool highlighted;
  const _AmountRow(
      this.label,
      this.amount, {
        this.color,
        this.bold = false,
        this.highlighted = false,
      });

  @override
  Widget build(BuildContext context) {
    final sign = amount < 0 ? '-' : '';
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: highlighted ? 8 : 0),
      decoration: highlighted
          ? BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? AppColors.black : AppColors.textMuted,
              fontSize: bold ? 13 : 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            '$sign₹${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: bold ? 13 : 12,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label, subtitle;
  final bool value, groupValue;
  final Function(bool) onChanged;

  const _PaymentOption({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => onChanged(v!),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}