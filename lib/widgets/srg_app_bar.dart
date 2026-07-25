import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/app_images.dart';
import 'package:dcs_app/providers/wishlist_provider.dart';
import 'package:dcs_app/providers/auth_provider.dart';
import 'package:dcs_app/providers/cart_provider.dart'; // ✅ NEW: for cartCountProvider

class SRGAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const SRGAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistCount = ref.watch(wishlistCountProvider);
    final cartCount = ref.watch(cartCountProvider); // ✅ NEW
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;

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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: AppColors.black),
                        onPressed: () {
                          if (!isLoggedIn) {
                            _showLoginRequiredSheet(context);
                          } else {
                            context.push('/wishlist');
                          }
                        },
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
                  // ✅ FIX: cart icon आता wishlist प्रमाणेच badge दाखवतो —
                  // cart मध्ये item add/remove केल्यावर लगेच count update होतो,
                  // कारण cartCountProvider हा cartProvider च्या state वर depend आहे.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.black),
                        onPressed: () => context.push('/cart'),
                      ),
                      if (cartCount > 0)
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
                                cartCount > 99 ? '99+' : '$cartCount',
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
    final cartCount = ref.watch(cartCountProvider); // ✅ NEW
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;

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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: AppColors.black),
                        onPressed: () {
                          if (!isLoggedIn) {
                            _showLoginRequiredSheet(context);
                          } else {
                            context.push('/wishlist');
                          }
                        },
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
                  // ✅ FIX: cart badge इथेही (sliver version) same प्रमाणे add केला
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.black),
                        onPressed: () => context.push('/cart'),
                      ),
                      if (cartCount > 0)
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
                                cartCount > 99 ? '99+' : '$cartCount',
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

// ── Login Required Bottom Sheet ──────────────────────────────────────
void _showLoginRequiredSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text(
            'Login Required',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please login to view and save items to your wishlist',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Login Now', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
          ),
        ],
      ),
    ),
  );
}