// lib/main.dart

import 'dart:async';
import 'package:dcs_app/screens/change_password_screen.dart';
import 'package:dcs_app/screens/contact_screen.dart';
import 'package:dcs_app/screens/delete_account_screen.dart';
import 'package:dcs_app/screens/edit_profile_screen.dart';
import 'package:dcs_app/screens/forgot_password_screen.dart';
import 'package:dcs_app/screens/privacy_policy_screen.dart';
import 'package:dcs_app/screens/terms_conditions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dcs_app/screens/blogs_screen.dart';
import 'package:dcs_app/screens/login_screen.dart';
import 'package:dcs_app/screens/register_screen.dart';
import 'package:dcs_app/screens/cart_screen.dart';
import 'package:dcs_app/screens/checkout_screen.dart';
import 'package:dcs_app/screens/profile_screen.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/feature_flags.dart';
import 'package:dcs_app/screens/home_screen.dart';
import 'package:dcs_app/services/api_client.dart';
import 'package:dcs_app/providers/auth_provider.dart';
import 'package:dcs_app/screens/wishlist_screen.dart';
import 'package:dcs_app/screens/orders_screen.dart';
import 'package:dcs_app/screens/order_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  ApiClient().init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: DCSApp(),
    ),
  );
}

// ✅ StateNotifier च्या state बदलावर GoRouter ला notify करणारा helper
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class DCSApp extends ConsumerStatefulWidget {
  const DCSApp({super.key});

  @override
  ConsumerState<DCSApp> createState() => _DCSAppState();
}

class _DCSAppState extends ConsumerState<DCSApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // ✅ 401 आल्यावर token clear होऊन login ला redirect
    ApiClient.onUnauthorized = () {
      _router.go('/login');
    };

    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(
        ref.read(authProvider.notifier).stream,
      ),
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        if (!authState.isInitialized) {
          return null;
        }

        final loggedIn  = authState.isLoggedIn;
        final location  = state.uri.toString();
        final loggingIn = location == '/login' || location == '/register';

        // ✅ Logged in user login page वर गेला तर home ला
        if (loggedIn && loggingIn) {
          return '/';
        }

        // // ✅ या pages साठी login required
        // if (!loggedIn && location == '/checkout') {
        //   return '/login';
        // }
        if (!loggedIn && location == '/orders') {
          return '/login';
        }
        if (!loggedIn && location.startsWith('/orders/')) {
          return '/login';
        }
        if (!loggedIn && location == '/wishlist') {
          return '/login';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MainShell(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/wishlist',
          builder: (context, state) => const WishlistScreen(),
        ),
        GoRoute(
          path: '/contact',
          builder: (context, state) => const ContactScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const ChangePasswordScreen(),
        ),
        GoRoute(
          path: '/privacy-policy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        GoRoute(
          path: '/terms-conditions',
          builder: (context, state) => const TermsConditionsScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/delete-account',
          builder: (context, state) => const DeleteAccountScreen(),
        ),
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return OrderDetailScreen(orderId: id);

          },

        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Deep Cleaning Solutions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> get _screens {
    final screens = <Widget>[const HomeScreen()];
    if (FeatureFlags.showBlogs)  screens.add(const BlogsScreen());
    // ✅ CHANGED: embedded: true — bottom nav tab असल्यामुळे back button दाखवायची गरज नाही
    if (FeatureFlags.showOrders) screens.add(const OrdersScreen(embedded: true));
    screens.add(const ProfileScreen());
    return screens;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = <_NavItem>[
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        index: 0,
        current: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    ];

    int idx = 1;
    if (FeatureFlags.showBlogs) {
      items.add(_NavItem(
        icon: Icons.article_outlined,
        activeIcon: Icons.article,
        label: 'Blogs',
        index: idx++,
        current: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ));
    }
    if (FeatureFlags.showOrders) {
      items.add(_NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: 'Orders',
        index: idx++,
        current: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ));
    }
    items.add(_NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      index: idx++,
      current: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
    ));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(children: items),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 20 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}