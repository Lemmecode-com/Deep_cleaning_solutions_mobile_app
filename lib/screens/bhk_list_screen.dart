// lib/screens/bhk_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/app_images.dart';
import 'package:dcs_app/widgets/app_network_image.dart';
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/utils/service_catalog.dart'; // ✅ नवीन import
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

  // ❌ जुने _furnishedServices आणि _unfurnishedServices maps इथून काढले —
  // आता ते ServiceCatalog मध्ये (lib/utils/service_catalog.dart) आहेत.

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  // ✅ NEW: fetch logic काढून वेगळ्या method मध्ये टाकली — initState आणि
  // pull-to-refresh दोन्ही हीच वापरतात, code duplicate नाही.
  Future<void> _loadData() async {
    if (widget.type == 'Furnished') {
      await ref.read(productProvider.notifier).getFurnishedFlats();
    } else {
      await ref.read(productProvider.notifier).getUnfurnishedFlats();
    }
    await ref.read(wishlistProvider.notifier).getWishlist();
  }

  // ✅ CHANGED: आता ServiceCatalog मधून services घेतो
  List<Map<String, String>> _getServices(String bhk) {
    final index = _bhkList.indexWhere((e) => e['name'] == bhk);
    return ServiceCatalog.byIndex(
      index == -1 ? 0 : index,
      isFurnished: widget.type == 'Furnished',
    );
  }

  String _getImageUrl(int index) {
    if (widget.type == 'Furnished') {
      return AppImages.furnishedBHK[index % AppImages.furnishedBHK.length];
    }
    return AppImages.unfurnishedBHK[index % AppImages.unfurnishedBHK.length];
  }

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

    // ✅ FIX: नवीन snackbar दाखवण्याआधी आधीचा/queue मधला snackbar clear
    // करतो — नाहीतर पटापट tap केल्यास snackbars एकामागोमाग queue होत
    // राहतात आणि तो "कधीच जात नाही" असं वाटतं.
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    // ✅ FIX: message, Login बटण आणि X icon आता तिन्ही एकाच row मध्ये.
    Widget snackContent(String text, {VoidCallback? onLogin}) => Row(
      children: [
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
        if (onLogin != null) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onLogin,
            child: const Text(
              'Login',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => messenger.hideCurrentSnackBar(),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        ),
      ],
    );

    if (result == 'login_required') {
      messenger.showSnackBar(
        SnackBar(
          content: snackContent(
            'Login to save items to your wishlist',
            onLogin: () => context.push('/login'),
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (result == 'success') {
      messenger.showSnackBar(
        SnackBar(
          content: snackContent('Added to wishlist!'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (result == 'removed') {
      messenger.showSnackBar(
        SnackBar(
          content: snackContent('Removed from wishlist'),
          backgroundColor: AppColors.textMuted,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    ref.watch(wishlistProvider);

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
      // ✅ NEW: pull-to-refresh added — top वरून खाली ओढल्यावर _loadData()
      // (furnished/unfurnished flats + wishlist) परत fetch होतो.
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          // content screen भरण्याइतकं नसेल तरीही pull-to-refresh काम
          // करावं म्हणून AlwaysScrollableScrollPhysics आवश्यक आहे.
          physics: const AlwaysScrollableScrollPhysics(),
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

                  final productId = _getProductIdFromList(products, i);
                  final slug      = _getSlugFromList(products, i);
                  final sqftMin   = _getSqftMinFromList(products, i);
                  final sqftMax   = _getSqftMaxFromList(products, i);

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
                      // ✅ FIX: कार्ड्समध्ये (categories) जास्त space हवा
                      // होता म्हणून bottom margin 18 वरून 28 केला.
                      margin: const EdgeInsets.only(bottom: 28),
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
                            child: Text(
                              fullName,
                              style: TextStyle(
                                fontSize: R.sp(context, 15),
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
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
      ),
    );
  }
}