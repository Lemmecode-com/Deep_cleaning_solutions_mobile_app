// lib/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/providers/cart_provider.dart';
import 'package:dcs_app/providers/order_provider.dart';
import 'package:dcs_app/providers/auth_provider.dart';
import 'package:dcs_app/widgets/terms_checkbox.dart';

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

  final _flatCtrl        = TextEditingController(); // Flat / Bungalow No. *
  final _wingCtrl        = TextEditingController(); // Wing (optional)
  final _societyCtrl     = TextEditingController(); // Society / Property Name *
  final _landmarkCtrl    = TextEditingController(); // Landmark (optional)

  // City/state text fields removed entirely. City now comes from the
  // branch the user picked on the Cart screen (see initState below) and
  // is shown read-only here; state is ALWAYS server-derived from branch_id.
  final _zipCtrl         = TextEditingController();
  final _couponCtrl      = TextEditingController();
  final _notesCtrl       = TextEditingController();

  // ✅ CHANGED: city selection now happens on the Cart screen, not here.
  // This just mirrors whatever branch cartProvider has selected (read-only
  // in this screen) — see initState().
  int? _selectedBranchId;

  // Area (city_area) selected from GET /checkout/init → city_areas,
  // scoped to _selectedBranchId. No default — user must pick a valid area
  // id, server rejects unknown ids with 422.
  int? _selectedAreaId;

  String? _selectedDate;
  String? _selectedTime;
  bool _isAdvancePayment = false;
  bool _isPlacingOrder   = false;

  // ✅ NEW: mandatory Terms & Conditions / Privacy Policy agreement
  bool _agreedToTerms = false;

  final GlobalKey _bottomBarKey = GlobalKey();
  double _bottomBarHeight = 160;

  void _measureBottomBar() {
    final ctx = _bottomBarKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final measured = box.size.height;
    if ((measured - _bottomBarHeight).abs() > 0.5) {
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

      // ✅ CHANGED: city is decided on the Cart screen (cartProvider.
      // selectedBranchId), not re-picked here. If the user already chose
      // a city there, lock it in and load areas for THAT branch.
      // Edge case fallback (e.g. deep link straight into checkout without
      // visiting Cart first): use branch_id=1 purely to populate the
      // `branches` list so a name can still resolve later — the UI below
      // will prompt the user to go back and pick a city instead of
      // silently showing a wrong one.
      final cartBranchId = ref.read(cartProvider).selectedBranchId;
      setState(() => _selectedBranchId = cartBranchId);
      ref.read(orderProvider.notifier).getCheckoutInit(branchId: cartBranchId ?? 1);
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

  ({String apartment, String address}) _buildApartmentAndAddress() {
    final apartment = [_flatCtrl.text.trim(), _wingCtrl.text.trim()]
        .where((s) => s.isNotEmpty)
        .join(', ');
    final address = [_societyCtrl.text.trim(), _landmarkCtrl.text.trim()]
        .where((s) => s.isNotEmpty)
        .join(', ');
    return (apartment: apartment, address: address);
  }

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
        _selectedTime = null;
      });
      if (mounted) {
        ref.read(orderProvider.notifier).getTimeSlots(date: _selectedDate!);
      }
    }
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
      // ✅ CHANGED: message now points back to Cart, since that's where
      // city selection actually happens.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your city on the Cart page'), backgroundColor: AppColors.secondary),
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

    // ✅ NEW: block order placement until Terms & Privacy Policy are accepted
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms & Conditions and Privacy Policy'), backgroundColor: AppColors.secondary),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      bool success = false;

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

        // ✅ FIX: guest user आहे का ते चेक करतो. `authProvider.user == null`
        // म्हणजे guest.
        final isGuest = ref.read(authProvider).user == null;

        if (mounted) {
          if (redirectUrl != null && redirectUrl.isNotEmpty) {
            // ✅ FIX: launchUrl (external browser) फक्त browser उघडतो आणि
            // लगेच परत येतो — payment प्रत्यक्षात पूर्ण झालं की नाही ते
            // इथे कळत नाही. त्यामुळे payment अजून बाकी असतानाच "Order
            // placed successfully!" दाखवणं चुकीचं होतं — ते काढलं.
            if (isGuest) {
              // ✅ FIX: guest साठी /orders ला login लागतो, त्यामुळे तो
              // चुकून login page वर फेकला जायचा. आता guest ला थेट Home वर
              // पाठवतो — payment browser मध्ये सुरूच राहील, तो पूर्ण करून
              // परत आल्यावर login केल्यास order त्याला दिसेल.
              context.go('/');
            } else {
              context.go('/orders');
            }
          } else {
            // Redirect नसेल (म्हणजे लगेच order confirm झालेला असेल)
            // तरच खरा "successful" message दाखवायचा.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order placed successfully!'),
                backgroundColor: AppColors.green,
              ),
            );
            context.go(isGuest ? '/' : '/orders');
          }
        }
      } else if (mounted) {
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

  // ✅ FIX: cart items ata branch-aware price sobat map hotात. Cart screen
  // sarkhach `cartProvider.notifier.finalPriceFor(rowId)` vaparун price
  // kadhтоय, ऐवजी raw `item['price']` var avalambun rahण्याच्या — jyamule
  // aadhi Order Summary madhe wrong (default) price yet hota.
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
                          // ✅ FIX: branch-aware price (finalPriceFor) prati
                          // item resolve करून _CartLineItem la pass kartоय.
                          ...cartState.cartItems.map((item) {
                            final rowId = item['rowId']?.toString() ?? '';
                            final branchPrice = cartState.hasBranchSelected
                                ? ref.read(cartProvider.notifier).finalPriceFor(rowId)
                                : null;
                            return _CartLineItem(item: item, branchPrice: branchPrice);
                          }),
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

    final hasSummary = _selectedAreaId != null &&
        (orderState.grandTotal > 0 || orderState.selectedAreaId == _selectedAreaId);

    final displayTotal = hasSummary
        ? (_isAdvancePayment ? orderState.advanceAmount : orderState.grandTotal)
        : cartState.finalAmount;

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
          await ref.read(orderProvider.notifier).getCheckoutInit(branchId: _selectedBranchId ?? 1);
          if (_selectedDate != null) {
            await ref.read(orderProvider.notifier).getTimeSlots(date: _selectedDate!);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

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

                _SectionTitle('Service Location'),
                const SizedBox(height: 10),

                // ✅ CHANGED: city is READ-ONLY here — already picked on
                // the Cart screen (which also set the session branch via
                // POST /cart/set-branch). No "Change" option here anymore;
                // city can only be changed from the Cart screen.
                _buildCityDisplay(orderState),
                const SizedBox(height: 10),

                if (_selectedBranchId != null) ...[
                  _buildAreaDropdown(orderState),
                  const SizedBox(height: 10),
                ],

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
                _buildField(_zipCtrl, 'PIN Code', keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : (v.length != 6 ? '6 digits required' : null)),

                const SizedBox(height: 20),

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

                if (_selectedDate != null) ...[
                  const SizedBox(height: 12),
                  if (orderState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (orderState.timeSlots.isNotEmpty) ...[
                    const Text('Select Time Slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: orderState.timeSlots.entries.toList().asMap().entries.map((indexed) {
                        final isLast = indexed.key == orderState.timeSlots.entries.length - 1;
                        final entry  = indexed.value;
                        final key   = entry.key;
                        final label = entry.value is Map ? (entry.value['label'] ?? key) : key;
                        final time  = entry.value is Map ? (entry.value['time'] ?? key) : key;
                        final isSelected = _selectedTime == key;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTime = key),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label.toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textMuted),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Starting from ${time.toString()}',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.black),
                                    ),
                                  ],
                                ),
                              ),
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

                _SectionTitle('Coupon Code'),
                const SizedBox(height: 10),
                _buildCouponSection(orderState),

                const SizedBox(height: 20),

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

                const SizedBox(height: 16),

                // ✅ NEW: mandatory Terms & Conditions / Privacy Policy checkbox.
                // Shown here so BOTH logged-in and guest users see it before
                // placing an order — guest checkout never visits Profile,
                // so this is the only reliable place they'll see it.
                TermsCheckbox(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v),
                ),

                SizedBox(height: _bottomBarHeight + 16),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: Container(
        key: _bottomBarKey,
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

  Widget _buildCityDisplay(OrderState orderState) {
    if (orderState.isInitLoading && orderState.branches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedBranchId == null) {
      return Container(
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
            const Expanded(
              child: Text(
                'Please select your city on the Cart page first',
                style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => context.canPop() ? context.pop() : context.go('/cart'),
              child: const Text('Go to Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    final match = orderState.branches.firstWhere(
          (b) => b['id'] == _selectedBranchId,
      orElse: () => const {},
    );
    final city  = match['city']?.toString()  ?? '';
    final state = match['state']?.toString() ?? '';
    final label = state.isNotEmpty ? '$city, $state' : city;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label.isNotEmpty ? label : 'Loading city...',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: `as int` / `as num` unsafe casts काढले. आता `as int?` /
  // `as num?` वापरून, backend ने कधी अनपेक्षित (null/string) type
  // पाठवली तरी entire dropdown build क्रॅश होणार नाही — फक्त तो
  // विशिष्ट area silently वगळला जाईल (whereType filter). Valid data
  // (जे normally असतंच) असताना behavior आधीसारखंच राहते.
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
            final id     = area['id'] as int?;
            final name   = area['name']?.toString() ?? '';
            final charge = (area['shipping_charge'] as num?) ?? 0;
            if (id == null) return null;
            return DropdownMenuItem<int>(
              value: id,
              child: Text('$name  (+₹${charge.toStringAsFixed(0)})'),
            );
          }).whereType<DropdownMenuItem<int>>().toList(),
          onChanged: _onAreaChanged,
          validator: (v) => v == null ? 'Please select your area' : null,
        ),
      ),
    );
  }

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

class _CartLineItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final double? branchPrice;
  const _CartLineItem({required this.item, this.branchPrice});

  @override
  Widget build(BuildContext context) {
    final name  = (item['name'] ?? item['service_name'] ?? '').toString();
    final price = branchPrice ?? item['price'];
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