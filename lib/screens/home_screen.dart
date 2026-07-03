// home_screen.dart - Fixed FAB (always visible, stacked)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dcs_app/screens/services_section.dart';
import 'package:dcs_app/widgets/srg_app_bar.dart';
import 'package:dcs_app/screens/why_choose_us_section.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/screens/banner_section.dart';
import 'package:dcs_app/screens/faq_section.dart';
import 'package:dcs_app/screens/how_we_work_section.dart';
import 'package:dcs_app/screens/our_team_section.dart';
import 'package:dcs_app/providers/home_provider.dart';
import 'package:dcs_app/providers/auth_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  final String _whatsappNumber = '918485854972';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(homeProvider.notifier).getHomeData(),
    );
  }

  Future<void> _openWhatsApp() async {
    final url = Uri.parse('https://wa.me/$_whatsappNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openContact() {
    context.push('/contact');
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final authState = ref.watch(authProvider);

    if (!authState.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      // ✅ drawer नाही
      body: Stack(
        children: [
          // ── Main Content ──────────────────────────────
          homeState.isLoading
              ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
              : homeState.error != null
              ? _ErrorWidget(
            error: homeState.error!,
            onRetry: () => ref.read(homeProvider.notifier).refresh(),
          )
              : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(homeProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                const SRGSliverAppBar(),
                SliverList(
                  delegate: SliverChildListDelegate([
                    BannerSection(banners: homeState.banners),
                    if (!authState.isLoggedIn)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Login / Register',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ServicesSection(categories: homeState.categories),
                    const SizedBox(height: 8),
                    OurTeamSection(team: homeState.team),
                    const SizedBox(height: 8),
                    const WhyChooseUsSection(),
                    const SizedBox(height: 8),
                    const HowWeWorkSection(),
                    const SizedBox(height: 8),
                    FAQSection(faqs: homeState.faqs),
                    const SizedBox(height: 100), // FAB साठी space
                  ]),
                ),
              ],
            ),
          ),

          // ── Fixed FAB Buttons (bottom right) ──────────
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ✅ Message / Contact FAB (वर)
                _FabButton(
                  onTap: _openContact,
                  backgroundColor: AppColors.secondary,
                  icon: FontAwesomeIcons.message,
                  iconColor: Colors.white,
                ),
                const SizedBox(height: 12),

                // ✅ WhatsApp FAB (खाली)
                _FabButton(
                  onTap: _openWhatsApp,
                  backgroundColor: const Color(0xFF25D366),
                  icon: FontAwesomeIcons.whatsapp,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── FAB Button Widget ──────────────────────────────────────────────────
class _FabButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final dynamic icon;  // ✅ IconData ऐवजी dynamic
  final Color iconColor;

  const _FabButton({
    required this.onTap,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: FaIcon(icon, color: iconColor, size: 24), // ✅ FaIcon वापरा
        ),
      ),
    );
  }
}

// ── Error Widget ───────────────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.secondary, size: 64),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Try Again',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}