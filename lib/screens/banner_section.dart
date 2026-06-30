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
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          SizedBox(
            height: R.wp(context, 56),
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _banners.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => _BannerCard(data: _banners[i]),
            ),
          ),
          const SizedBox(height: 10),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF3A1F6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data['tag']!,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['title']!,
            style: TextStyle(
              color: Colors.white,
              fontSize: R.sp(context, 18),
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data['sub']!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: R.sp(context, 11),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}