import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/widgets/section_title.dart';
import 'package:dcs_app/screens/flat_category_screen.dart';
import 'package:dcs_app/screens/enquiry_form_screen.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/app_images.dart';
import 'package:dcs_app/widgets/app_network_image.dart';

class ServicesSection extends StatelessWidget {
  final List<dynamic> categories;

  const ServicesSection({
    super.key,
    this.categories = const [],
  });

  static const List<Map<String, dynamic>> _staticServices = [
    {'name': 'Flats',       'image': AppImages.flat,       'isNew': false},
    {'name': 'Bungalows',   'image': AppImages.bungalow,   'isNew': false},
    {'name': 'Offices',     'image': AppImages.office,     'isNew': false},
    {'name': 'Societies',   'image': AppImages.society,    'isNew': false},
    {'name': 'Restaurant',  'image': AppImages.restaurant, 'isNew': false},
    {'name': 'Shops',       'image': AppImages.shop,       'isNew': false},
    {'name': 'School',      'image': AppImages.school,     'isNew': false},
    {'name': 'Car Wash',    'image': AppImages.carWash,    'isNew': true},
  ];

  List<Map<String, dynamic>> get _services {
    if (categories.isNotEmpty) {
      return categories.map((c) => {
        'name':  (c['name']  ?? '').toString(),
        'image': (c['image'] ?? c['icon'] ?? AppImages.flat).toString(),
        'isNew': c['is_new'] ?? false,
      }).toList();
    }
    return _staticServices;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          const SectionTitle('Cleaning Services'),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => ServiceCard(data: _services[i]),
          ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const ServiceCard({super.key, required this.data});

  void _navigateMain(BuildContext context) {
    final name = data['name'] as String;
    if (name == 'Flats') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const FlatCategoryScreen(),
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => EnquiryFormScreen(serviceName: name),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w    = R.w(context) - 32;
    final imgH = w * 0.6;
    final name = data['name'] as String;

    return GestureDetector(
      onTap: () => _navigateMain(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: w,
              height: imgH,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  AppNetworkImage(
                    url: data['image'] as String,
                    width: w,
                    height: imgH,
                    fit: BoxFit.cover,
                  ),

                  // Dark gradient overlay
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: imgH * 0.35,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.45), Colors.transparent],
                        ),
                      ),
                    ),
                  ),

                  // ✅ Cart icon — image च्या top-right ला
                  Positioned(
                    top: 10, right: 10,
                    child: _OverlayBtn(
                      icon: Icons.shopping_bag_outlined,
                      onTap: () {
                        if (name == 'Flats') {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const FlatCategoryScreen(),
                          ));
                        } else {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => EnquiryFormScreen(serviceName: name),
                          ));
                        }
                      },
                    ),
                  ),

                  // NEW badge — top-right वर cart icon आल्यामुळे थोडं खाली शिफ्ट केलं, जेणेकरून overlap होणार नाही
                  if (data['isNew'] == true)
                    Positioned(
                      top: 56, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: R.sp(context, 16),
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (_) => const Icon(Icons.star, color: AppColors.star, size: 16)),
          ),
        ],
      ),
    );
  }
}

class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _OverlayBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
        ),
        child: Icon(icon, size: 18, color: AppColors.black),
      ),
    );
  }
}