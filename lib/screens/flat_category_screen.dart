import 'package:flutter/material.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/app_images.dart';
import 'package:dcs_app/widgets/app_network_image.dart';
import 'package:dcs_app/utils/responsive.dart';

import 'bhk_list_screen.dart';

class FlatCategoryScreen extends StatelessWidget {
  const FlatCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Flat Cleaning',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'Select Your Flat Category',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: R.sp(context, 20),
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 20),
            _FlatCategoryCard(
              title: 'Furnished Flats',
              imageUrl: AppImages.furnishedFlat,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BHKListScreen(type: 'Furnished'),
                ),
              ),
            ),
            // ✅ FIX: प्रत्येक category आता स्वतःच्या bordered card मध्ये
            // असल्यामुळे थोडं कमी gap पुरेसं आहे.
            const SizedBox(height: 20),
            _FlatCategoryCard(
              title: 'Unfurnished Flats',
              imageUrl: AppImages.unfurnishedFlat,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BHKListScreen(type: 'Unfurnished'),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FlatCategoryCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const _FlatCategoryCard({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // ✅ FIX: image + title + button भोवती एक border/card टाकला —
      // त्यामुळे कुठलं "EXPLORE NOW" बटण कुठल्या category चं आहे ते
      // स्पष्ट दिसेल (आधी दोन्ही categories मध्ये फक्त space होतं,
      // ownership स्पष्ट दिसत नव्हती).
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            AppNetworkImage(
              url: imageUrl,
              width: double.infinity,
              height: R.wp(context, 62),
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: R.sp(context, 15),
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
              child: const Text(
                'EXPLORE NOW',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}