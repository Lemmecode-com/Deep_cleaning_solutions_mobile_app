// lib/screens/bhk_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/app_images.dart';
import 'package:dcs_app/widgets/app_network_image.dart';
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/providers/product_provider.dart';
import 'package:dcs_app/providers/wishlist_provider.dart';
import 'package:go_router/go_router.dart';
import 'service_detail_sheet.dart';

class BHKListScreen extends ConsumerStatefulWidget {
  final String type;
  const BHKListScreen({super.key, required this.type});

  @override
  ConsumerState<BHKListScreen> createState() => _BHKListScreenState();
}

class _BHKListScreenState extends ConsumerState<BHKListScreen> {

  static const List<Map<String, dynamic>> _bhkList = [
    {'name': '1 BHK'},
    {'name': '2 BHK'},
    {'name': '3 BHK'},
    {'name': '4 BHK'},
    {'name': '5 BHK'},
  ];

  static const Map<String, List<Map<String, String>>> _furnishedServices = {
    '1 BHK': [
      {'title': 'Hall Cleaning',     'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Cabinets Cleaning (Inside & Outside), Fans/AC, Floor Scrubbing & Mopping, Tables/Chairs/Lamp/Frames/TV set etc.'},
      {'title': 'Bedroom Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Cabinets Cleaning (Inside & Outside), Fans/AC, Floor Scrubbing & Mopping, Bed (Inside/Outside)'},
      {'title': 'Kitchen Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans, Floor Scrubbing & Mopping, Chimney/Stove (Exterior), Cabinets & Trolly Cleaning (Inside & Outside, Steam Cleaner)'},
      {'title': 'Bathroom Cleaning', 'desc': 'Commode Pot Cleaning, Shower, Taps, Exhaust (WetWiping), Hard Stain Removal, Drill Brush Scrubbing, Sink Cleaning, Mirrors/Glass wiping'},
      {'title': 'Balcony Cleaning',  'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
    ],
    '2 BHK': [
      {'title': 'Hall Cleaning',     'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Cabinets Cleaning (Inside & Outside), Fans/AC, Floor Scrubbing & Mopping'},
      {'title': 'Bedroom Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Cabinets (Inside & Outside), Fans/AC, Floor Scrubbing, Bed (Inside/Outside) — 2 Bedrooms'},
      {'title': 'Kitchen Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans, Floor Scrubbing & Mopping, Chimney/Stove (Exterior), Steam Cleaner'},
      {'title': 'Bathroom Cleaning', 'desc': 'Commode Pot Cleaning, Shower, Taps, Exhaust (WetWiping), Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 2 Bathrooms'},
      {'title': 'Balcony Cleaning',  'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
    ],
    '3 BHK': [
      {'title': 'Hall Cleaning',     'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing & Mopping, Tables/Chairs/Lamp/Frames/TV set etc.'},
      {'title': 'Bedroom Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing, Bed (Inside/Outside) — 3 Bedrooms'},
      {'title': 'Kitchen Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans, Floor Scrubbing, Chimney/Stove (Exterior), Cabinets & Trolly (Steam Cleaner)'},
      {'title': 'Bathroom Cleaning', 'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 3 Bathrooms'},
      {'title': 'Balcony Cleaning',  'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
    ],
    '4 BHK': [
      {'title': 'Hall Cleaning',     'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing & Mopping'},
      {'title': 'Bedroom Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing, Bed (Inside/Outside) — 4 Bedrooms'},
      {'title': 'Kitchen Cleaning',  'desc': 'Dry Dusting, Vacuuming, Fans, Floor Scrubbing, Chimney/Stove (Exterior), Cabinets & Trolly (Steam Cleaner)'},
      {'title': 'Bathroom Cleaning', 'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 4 Bathrooms'},
      {'title': 'Balcony Cleaning',  'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
    ],
    '5 BHK': [
      {'title': 'Hall Cleaning',     'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing & Mopping'},
      {'title': 'Bedroom Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing, Bed (Inside/Outside) — 5 Bedrooms'},
      {'title': 'Kitchen Cleaning',  'desc': 'Dry Dusting, Vacuuming, Fans, Floor Scrubbing, Chimney/Stove (Exterior), Cabinets & Trolly (Steam Cleaner)'},
      {'title': 'Bathroom Cleaning', 'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 5 Bathrooms'},
      {'title': 'Balcony Cleaning',  'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
    ],
  };

  static const Map<String, List<Map<String, String>>> _unfurnishedServices = {
    '1 BHK': [
      {'title': 'Hall & Bedroom Cleaning', 'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Cabinets Cleaning (Outside), Fans/AC, Floor Scrubbing & Mopping'},
      {'title': 'Kitchen Cleaning',        'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans, Floor Scrubbing & Mopping, Chimney/Stove (Exterior Cleaning)'},
      {'title': 'Bathroom Cleaning',       'desc': 'Commode Pot Cleaning, Shower, Taps, Exhaust (WetWiping), Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping'},
      {'title': 'Balcony Cleaning',        'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
    ],
    '2 BHK': [
      {'title': 'Hall & Bedroom Cleaning', 'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Cabinets Cleaning (Outside), Fans/AC, Floor Scrubbing & Mopping — 2 Bedrooms'},
      {'title': 'Kitchen Cleaning',        'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans, Floor Scrubbing & Mopping, Chimney/Stove (Exterior Cleaning)'},
      {'title': 'Bathroom Cleaning',       'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 2 Bathrooms'},
      {'title': 'Balcony Cleaning',        'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
    ],
    '3 BHK': [
      {'title': 'Hall & Bedroom Cleaning', 'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing & Mopping — 3 Bedrooms'},
      {'title': 'Kitchen Cleaning',        'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans, Floor Scrubbing, Chimney/Stove (Exterior Cleaning)'},
      {'title': 'Bathroom Cleaning',       'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 3 Bathrooms'},
      {'title': 'Balcony Cleaning',        'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
    ],
    '4 BHK': [
      {'title': 'Hall & Bedroom Cleaning', 'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing & Mopping — 4 Bedrooms'},
      {'title': 'Kitchen Cleaning',        'desc': 'Dry Dusting, Vacuuming, Fans, Floor Scrubbing, Chimney/Stove (Exterior Cleaning)'},
      {'title': 'Bathroom Cleaning',       'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 4 Bathrooms'},
      {'title': 'Balcony Cleaning',        'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
    ],
    '5 BHK': [
      {'title': 'Hall & Bedroom Cleaning', 'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing & Mopping — 5 Bedrooms'},
      {'title': 'Kitchen Cleaning',        'desc': 'Dry Dusting, Vacuuming, Fans, Floor Scrubbing, Chimney/Stove (Exterior Cleaning)'},
      {'title': 'Bathroom Cleaning',       'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 5 Bathrooms'},
      {'title': 'Balcony Cleaning',        'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
    ],
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.type == 'Furnished') {
        ref.read(productProvider.notifier).getFurnishedFlats();
      } else {
        ref.read(productProvider.notifier).getUnfurnishedFlats();
      }
      ref.read(wishlistProvider.notifier).getWishlist();
    });
  }

  List<Map<String, String>> _getServices(String bhk) {
    if (widget.type == 'Furnished') {
      return _furnishedServices[bhk] ?? _furnishedServices['1 BHK']!;
    }
    return _unfurnishedServices[bhk] ?? _unfurnishedServices['1 BHK']!;
  }

  String _getImageUrl(int index) {
    if (widget.type == 'Furnished') {
      return AppImages.furnishedBHK[index % AppImages.furnishedBHK.length];
    }
    return AppImages.unfurnishedBHK[index % AppImages.unfurnishedBHK.length];
  }

  // ✅ FIXED: ref.read cha naahi, direct products list pass karo
  int? _getProductIdFromList(List<dynamic> products, int index) {
    if (products.isNotEmpty && index < products.length) {
      return products[index]['id'] as int?;
    }
    return null;
  }

  String? _getSlugFromList(List<dynamic> products, int index) {
    if (products.isNotEmpty && index < products.length) {
      return products[index]['slug'] as String?;
    }
    return null;
  }

  // ✅ NEW: sqft_min / sqft_max थेट backend च्या product object मधून —
  // कुठलाही range इथे hardcode केलेला नाही, जो असेल तोच वापरला जातो.
  num? _getSqftMinFromList(List<dynamic> products, int index) {
    if (products.isNotEmpty && index < products.length) {
      final v = products[index]['sqft_min'];
      if (v is num) return v;
      if (v is String) return num.tryParse(v);
    }
    return null;
  }

  num? _getSqftMaxFromList(List<dynamic> products, int index) {
    if (products.isNotEmpty && index < products.length) {
      final v = products[index]['sqft_max'];
      if (v is num) return v;
      if (v is String) return num.tryParse(v);
    }
    return null;
  }

  Future<void> _onWishlistTap(int productId) async {
    final result = await ref
        .read(wishlistProvider.notifier)
        .toggleWishlist(productId);

    if (!mounted) return;

    if (result == 'login_required') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please login to add to wishlist'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Login',
            textColor: Colors.white,
            onPressed: () => context.push('/login'),
          ),
        ),
      );
    } else if (result == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Added to wishlist!'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (result == 'removed') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Removed from wishlist'),
          backgroundColor: AppColors.textMuted,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: ref.watch vaparla — dono sathi reactive
    final productState = ref.watch(productProvider);
    ref.watch(wishlistProvider);

    // ✅ FIXED: build madhe products kadhla — reactive ahe
    final products = widget.type == 'Furnished'
        ? productState.furnishedFlats
        : productState.unfurnishedFlats;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.type} Flats',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: productState.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bhkList.length,
              itemBuilder: (_, i) {
                final bhkName  = _bhkList[i]['name'] as String;
                final fullName = '$bhkName ${widget.type} Homes';

                // ✅ FIXED: products directly vaparle — ref.watch(productProvider) already build madhe ahe
                final productId = _getProductIdFromList(products, i);
                final slug      = _getSlugFromList(products, i);
                final sqftMin   = _getSqftMinFromList(products, i);
                final sqftMax   = _getSqftMaxFromList(products, i);

                // ✅ FIXED: productId correct milto ata — heart reactive hoil
                final inWishlist = productId != null
                    ? ref.watch(isInWishlistProvider(productId))
                    : false;

                return GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ServiceDetailSheet(
                      title:     fullName,
                      services:  _getServices(bhkName),
                      productId: productId,
                      slug:      slug,
                      sqftMin:   sqftMin,
                      sqftMax:   sqftMax,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            AppNetworkImage(
                              url: _getImageUrl(i),
                              width: double.infinity,
                              height: R.wp(context, 45),
                              fit: BoxFit.cover,
                            ),

                            // BHK size badge — the only label shown on the image
                            Positioned(
                              bottom: 10, left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  bhkName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),

                            // ✅ Heart icon — top right
                            Positioned(
                              top: 8, right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  if (productId != null) _onWishlistTap(productId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    inWishlist
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: inWishlist
                                        ? Colors.red
                                        : AppColors.textMuted,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  fullName,
                                  style: TextStyle(
                                    fontSize: R.sp(context, 15),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5, (_) => const Icon(Icons.star, color: AppColors.star, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}