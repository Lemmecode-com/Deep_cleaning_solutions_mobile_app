// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/widgets/srg_app_bar.dart';
import 'package:dcs_app/widgets/srg_drawer.dart';
import 'package:dcs_app/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _profileLoaded = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isLoggedIn && !_profileLoaded) {
      _profileLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && authState.isLoggedIn) {
          ref.read(authProvider.notifier).getProfile();
        }
      });
    }

    if (!authState.isLoggedIn) {
      _profileLoaded = false;
    }

    // ✅ Guest user ला login prompt दाखवा
    if (!authState.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        drawer: const SRGDrawer(),
        body: CustomScrollView(
          slivers: [
            const SRGSliverAppBar(),
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.purpleLight,
                        ),
                        child: const Icon(Icons.person_outline,
                            color: AppColors.primary, size: 48),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Login to view your profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Access your orders, wishlist and account details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go('/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Login',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go('/register'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Register',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Logged in user — normal profile
    final userName  = authState.user?['name']  ?? 'User';
    final userEmail = authState.user?['email'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const SRGDrawer(),
      body: CustomScrollView(
        slivers: [
          const SRGSliverAppBar(),
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF3A1F6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4), width: 2),
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 14),
                    authState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Welcome back!\n$userName',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: R.sp(context, 22),
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    if (userEmail.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: R.sp(context, 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Manage your account and track your cleaning services',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: R.sp(context, 13),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Orders Stats section काढलं — Orders आधीच स्वतंत्र tab मध्ये आहे

              // Menu Items
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10)
                  ],
                ),
                child: Column(
                  children: [
                    _ProfileMenuItem(
                        icon: Icons.person_outline,
                        label: 'My Profile',
                        onTap: () {}),
                    _ProfileMenuItem(
                        icon: Icons.favorite_outline,
                        label: 'Wishlist',
                        onTap: () => context.go('/wishlist')),
                    _ProfileMenuItem(
                        icon: Icons.lock_outline,
                        label: 'Change Password',
                        onTap: () => context.push('/change-password')), // ✅ push वापरला
                    _ProfileMenuItem(
                        icon: Icons.logout,
                        label: 'Logout',
                        isRed: true,
                        isLast: true,
                        onTap: _logout),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive, isRed, isLast;
  final VoidCallback onTap;

  const _ProfileMenuItem(
      {required this.icon,
        required this.label,
        this.isActive = false,
        this.isRed = false,
        this.isLast = false,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isRed
        ? AppColors.secondary
        : isActive
        ? AppColors.secondary
        : AppColors.black;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isActive ? AppColors.redLight : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? const Border(
                  left: BorderSide(color: AppColors.secondary, width: 3))
                  : null,
            ),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                        fontSize: R.sp(context, 14),
                        fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                        color: color),
                  ),
                ),
                if (!isRed)
                  Icon(Icons.chevron_right,
                      color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
                height: 1,
                color: AppColors.border,
                indent: 16,
                endIndent: 16),
        ],
      ),
    );
  }
}