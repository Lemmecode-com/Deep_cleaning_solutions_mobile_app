import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/app_images.dart';
import 'package:dcs_app/providers/wishlist_provider.dart';

class SRGAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const SRGAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistCount = ref.watch(wishlistCountProvider);

    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: null,
      flexibleSpace: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ✅ Logo — perfect center
            Center(
              child: Image.asset(
                AppImages.logo,
                height: 48,
                width: 140,
                fit: BoxFit.contain,
              ),
            ),

            // ✅ Left — Menu
            Positioned(
              left: 0,
              child: Builder(
                builder: (c) => IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.black),
                  onPressed: () => Scaffold.of(c).openDrawer(),
                ),
              ),
            ),

            // ✅ Right — Search + Wishlist + Cart
            Positioned(
              right: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.black),
                    onPressed: () {},
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: AppColors.black),
                        onPressed: () => context.push('/wishlist'),
                      ),
                      if (wishlistCount > 0)
                        Positioned(
                          top: 6, right: 6,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                wishlistCount > 99 ? '99+' : '$wishlistCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.black),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}

// Sliver version
class SRGSliverAppBar extends ConsumerWidget {
  const SRGSliverAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistCount = ref.watch(wishlistCountProvider);

    return SliverAppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      pinned: true,
      automaticallyImplyLeading: false,
      title: null,
      flexibleSpace: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ✅ Logo — perfect center
            Center(
              child: Image.asset(
                AppImages.logo,
                height: 48,
                width: 140,
                fit: BoxFit.contain,
              ),
            ),

            // ✅ Right — Search + Wishlist + Cart
            Positioned(
              right: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.black),
                    onPressed: () {},
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: AppColors.black),
                        onPressed: () => context.push('/wishlist'),
                      ),
                      if (wishlistCount > 0)
                        Positioned(
                          top: 6, right: 6,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                wishlistCount > 99 ? '99+' : '$wishlistCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.black),
                    onPressed: () => context.push('/cart'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}