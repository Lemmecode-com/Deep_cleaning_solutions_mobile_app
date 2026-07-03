import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/providers/cart_provider.dart';

class ServiceDetailSheet extends ConsumerStatefulWidget {
  final String title;
  final List<Map<String, String>> services;
  final int? productId;
  final String? slug;
  // ✅ backend च्या product object मधून आलेला sqft range — hardcoded नाही
  final num? sqftMin;
  final num? sqftMax;

  const ServiceDetailSheet({
    super.key,
    required this.title,
    required this.services,
    this.productId,
    this.slug,
    this.sqftMin,
    this.sqftMax,
  });

  @override
  ConsumerState<ServiceDetailSheet> createState() => _ServiceDetailSheetState();
}

class _ServiceDetailSheetState extends ConsumerState<ServiceDetailSheet> {
  final _sqftCtrl   = TextEditingController();
  bool _cleanWalls  = false;
  bool _cleanPaint  = false;
  bool _removeCover = false;
  bool _isLoading   = false;

  @override
  void dispose() {
    _sqftCtrl.dispose();
    super.dispose();
  }

  // ✅ Range कुठेही hardcode नाही — जे backend पाठवेल तेच hint मध्ये दिसेल.
  // backend ने range बदलला (min/max) तरी इथे काहीही बदलावं लागत नाही.
  String get _sqftHint {
    final min = widget.sqftMin;
    final max = widget.sqftMax;
    if (min != null && max != null) return 'Enter sq.ft. (min ${_fmt(min)} – max ${_fmt(max)})';
    if (min != null) return 'Enter sq.ft. (min ${_fmt(min)})';
    if (max != null) return 'Enter sq.ft. (max ${_fmt(max)})';
    return 'Enter sq.ft.';
  }

  // ✅ 650.0 → "650", 650.5 → "650.5" असं स्वच्छ दाखवतो (backend कडून जो number
  // आला तोच, फक्त फॉरमॅटिंग)
  String _fmt(num n) => n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toString();

  // ✅ backend कडून raw validation message आलाच (उदा. दुसऱ्या field साठी) तर तो
  // technical/Laravel-style वाक्य clean करून दाखवतो. यातले आकडे backend च्या
  // message मधूनच dynamically काढलेले असतात — कुठलाही range इथे hardcode नाही.
  String _humanizeError(String raw) {
    final lower = raw.toLowerCase();

    if (lower.contains('sqft') || lower.contains('sq.ft') || lower.contains('sq ft')) {
      final minMatch = RegExp(r'(?:at least|minimum of|min(?:imum)?)\D{0,15}?(\d+(\.\d+)?)').firstMatch(lower);
      final maxMatch = RegExp(r'(?:not (?:be )?greater than|no more than|maximum of|max(?:imum)?)\D{0,15}?(\d+(\.\d+)?)').firstMatch(lower);

      if (minMatch != null) {
        return 'Please enter at least ${minMatch.group(1)} sq.ft. for this service.';
      }
      if (maxMatch != null) {
        return 'This service is available up to ${maxMatch.group(1)} sq.ft. only. Please enter a valid sq.ft.';
      }
    }

    // unrecognized pattern → backend चा message जसाच्या तसा
    return raw;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.primary : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ✅ इथे कुठलाही client-side hardcoded validation message नाही.
  // sq.ft रिकामं/अवैध/500 पेक्षा कमी असेल तरी request backend कडे जाते
  // आणि backend जो validation error पाठवेल (422 चा errors object) तोच
  // जसाच्या तसा (ApiClient._extractServerMessage मार्फत) दाखवला जातो.
  Future<void> _addToCart() async {
    if (widget.productId == null) return;

    final double sqft = double.tryParse(_sqftCtrl.text.trim()) ?? 0;

    // ✅ backend कडून आधीच मिळालेला (dynamic) range वापरून लगेच, स्पष्ट भाषेत
    // सांगतो — number कुठेही hardcode नाही, तो widget.sqftMin/sqftMax मधून
    // (product data) येतो. Range बदलला तरी हा code तसाच राहतो.
    if (widget.sqftMin != null && sqft < widget.sqftMin!) {
      _showSnackBar(
        'Please enter at least ${_fmt(widget.sqftMin!)} sq.ft. for this service.',
        isError: true,
      );
      return;
    }
    if (widget.sqftMax != null && sqft > widget.sqftMax!) {
      _showSnackBar(
        'This service is available up to ${_fmt(widget.sqftMax!)} sq.ft. only. Please enter a valid sq.ft.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<Map<String, dynamic>> addons = [
        if (_cleanWalls)  {'product_id': 22},
        if (_cleanPaint)  {'product_id': 25},
        if (_removeCover) {'product_id': 26},
      ];

      final bool success = await ref.read(cartProvider.notifier).addFlatToCart(
        mainProductId: widget.productId!,
        sqft:          sqft,
        addons:        addons,
      );

      if (mounted) {
        if (success) {
          // ✅ show confirmation first, give it a moment to actually be seen,
          // then close the sheet and redirect to the cart page
          _showSnackBar('${widget.title} added to cart!');
          await Future.delayed(const Duration(milliseconds: 700));
          if (mounted) {
            Navigator.pop(context);
            context.go('/cart');
          }
        } else {
          // ✅ backend कडून आलेला actual error/validation message — पण जर तो
          // technical (raw Laravel style) असेल तर स्वच्छ भाषेत rewrite करतो
          final rawError = ref.read(cartProvider).error;
          if (rawError != null && rawError.isNotEmpty) {
            _showSnackBar(_humanizeError(rawError), isError: true);
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Scaffold(  // ✅ Scaffold add kela
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: R.sp(context, 16),
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addToCart,
                      icon: _isLoading
                          ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.shopping_cart, size: 14),
                      label: const Text(
                        'ADD TO CART',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: AppColors.textMuted, size: 22),
                    ),
                  ],
                ),
              ),

              // Cart count badge
              if (cartState.cartCount > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${cartState.cartCount} item(s) in cart',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 20),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    // Sq.ft input
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'How much sq.ft. is your property? ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                          ),
                          TextSpan(
                            text: '*',
                            style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _sqftCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: _sqftHint,
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Checkboxes
                    _CheckItem(
                      label: 'Do you want to clean walls and ceilings?',
                      value: _cleanWalls,
                      onChanged: (v) => setState(() => _cleanWalls = v!),
                    ),
                    _CheckItem(
                      label: 'Do you want to clean paint and adhesive stains?',
                      value: _cleanPaint,
                      onChanged: (v) => setState(() => _cleanPaint = v!),
                    ),
                    _CheckItem(
                      label: 'Do you want protective film/plastic cover removed from furniture?',
                      value: _removeCover,
                      onChanged: (v) => setState(() => _removeCover = v!),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 8),

                    // Services Included
                    const Text(
                      'Services Included:',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.black),
                    ),
                    const SizedBox(height: 12),

                    ...widget.services.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${s['title']} : ',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black),
                            ),
                            TextSpan(
                              text: s['desc'],
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    )),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),

                    // Add to Cart Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _addToCart,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.shopping_cart, size: 16),
                        label: const Text(
                          'ADD TO CART',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.black),
            ),
          ),
        ),
      ],
    );
  }
}