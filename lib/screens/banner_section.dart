import 'package:flutter/material.dart';
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/utils/app_colors.dart';

class BannerSection extends StatefulWidget {
  final List<dynamic> banners;

  const BannerSection({
    super.key,
    this.banners = const [],
  });

  @override
  State<BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<BannerSection> {
  int _current = 0;
  final PageController _ctrl = PageController();

  // ── Static fallback (API data नसेल तर) ───────────────────────────
  static const List<Map<String, String>> _staticBanners = [
    {'tag': 'Professional Cleaning', 'title': 'Expert Cleaning\nServices for You',  'sub': 'Trusted by 1400+ happy clients across Pune'},
  ];

  List<Map<String, String>> get _banners {
    if (widget.banners.isNotEmpty) {
      return widget.banners.map((b) => {
        'tag':   (b['tag']   ?? '').toString(),
        'title': (b['title'] ?? '').toString(),
        'sub':   (b['sub']   ?? b['description'] ?? '').toString(),
      }).toList();
    }
    return _staticBanners;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ RESPONSIVE FIX: height आता screen size प्रमाणे clamp केलेली आहे —
    // छोट्या फोनवर खूप उंच होत नाही, टॅबलेट/मोठ्या स्क्रीनवर खूप lहान होत नाही.
    // Note: तुमच्या R (responsive.dart) मध्ये hp() नाही, म्हणून
    // MediaQuery वापरून height % इथेच local पद्धतीने काढलं आहे.
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bannerHeight = R.wp(context, 56).clamp(170.0, screenHeight * 0.32);

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
      child: Column(
        children: [
          SizedBox(
            height: bannerHeight,
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _banners.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => _BannerCard(data: _banners[i]),
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
                  (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i ? AppColors.secondary : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Map<String, String> data;
  const _BannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: R.wp(context, 4)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF3A1F6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.all(R.wp(context, 4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: R.wp(context, 2.5),
              vertical: screenHeight * 0.005,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data['tag']!,
              style: TextStyle(
                color: Colors.white,
                fontSize: R.sp(context, 11),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          // ✅ RESPONSIVE FIX: overflow टाळण्यासाठी maxLines + ellipsis वापरलं आहे,
          // overflow होणार नाही, वेगवेगळ्या screen widths वर व्यवस्थित बसेल.
          Text(
            data['title']!,
            style: TextStyle(
              color: Colors.white,
              fontSize: R.sp(context, 18),
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            data['sub']!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: R.sp(context, 11),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: screenHeight * 0.012),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: R.wp(context, 4),
                vertical: screenHeight * 0.009,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              'Book Now',
              style: TextStyle(fontSize: R.sp(context, 12), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}