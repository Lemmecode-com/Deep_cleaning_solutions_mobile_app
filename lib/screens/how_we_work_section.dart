import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/widgets/section_title.dart';

import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/app_images.dart';
import 'package:dcs_app/widgets/app_network_image.dart';

class HowWeWorkSection extends StatefulWidget {
  const HowWeWorkSection({super.key});

  @override
  State<HowWeWorkSection> createState() => _HowWeWorkSectionState();
}

class _HowWeWorkSectionState extends State<HowWeWorkSection> {
  int _current = 0;
  final PageController _ctrl = PageController();
  Timer? _autoTimer;

  // Category -> images list (used to build the flattened slide list below)
  static final List<Map<String, dynamic>> _categories = [
    {'label': 'Kitchen Deep Cleaning', 'images': AppImages.kitchen},
    {'label': 'Bedroom Cleaning',      'images': AppImages.bedroom},
    {'label': 'Bathroom Cleaning',     'images': AppImages.bathroom},
    {'label': 'Hall Cleaning',         'images': AppImages.hall},
    {'label': 'Window Cleaning',       'images': AppImages.window},
    {'label': 'Floor Cleaning',        'images': AppImages.floor},
  ];

  // Flattened list: every single image (from every category) becomes its own slide,
  // paired with its category label — so ALL images get used, not just the first one.
  late final List<Map<String, String>> _items = _buildFlatItems();

  // Round-robin: one image from Kitchen, then one from Bedroom, then Bathroom,
  // Hall, Window, Floor — then back to Kitchen's 2nd image, and so on.
  // Categories with fewer images simply drop out once they run out.
  List<Map<String, String>> _buildFlatItems() {
    final List<Map<String, String>> flat = [];
    final maxLen = _categories
        .map((c) => (c['images'] as List<String>).length)
        .fold<int>(0, (a, b) => a > b ? a : b);

    for (int i = 0; i < maxLen; i++) {
      for (final cat in _categories) {
        final label = cat['label'] as String;
        final images = cat['images'] as List<String>;
        if (i < images.length) {
          flat.add({'label': label, 'image': images[i]});
        }
      }
    }
    return flat;
  }

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_ctrl.hasClients) return;
      final isLast = _current >= _items.length - 1;
      final nextPage = isLast ? 0 : _current + 1;
      _ctrl.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _restartAutoPlay() {
    // Reset the timer whenever the user manually interacts, so it doesn't
    // jump right after a manual swipe/tap.
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _prev() {
    if (_current > 0) {
      setState(() => _current--);
      _ctrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // wrap to last slide
      setState(() => _current = _items.length - 1);
      _ctrl.animateToPage(_current, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
    _restartAutoPlay();
  }

  void _next() {
    if (_current < _items.length - 1) {
      setState(() => _current++);
      _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // wrap to first slide
      setState(() => _current = 0);
      _ctrl.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
    _restartAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    final imgH = R.wp(context, 65);

    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          const SectionTitle('How We Work'),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: imgH,
                child: PageView.builder(
                  controller: _ctrl,
                  itemCount: _items.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    final imageUrl = item['image'] ?? '';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppNetworkImage(
                            url: imageUrl,
                            width: double.infinity,
                            height: imgH,
                            fit: BoxFit.cover,
                          ),
                          // Label overlay
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              ),
                              child: Text(
                                item['label'] ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Prev button
              Positioned(
                left: 20,
                child: GestureDetector(
                  onTap: _prev,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                    ),
                    child: const Icon(Icons.chevron_left, size: 20),
                  ),
                ),
              ),
              // Next button
              Positioned(
                right: 20,
                child: GestureDetector(
                  onTap: _next,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                    ),
                    child: const Icon(Icons.chevron_right, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}