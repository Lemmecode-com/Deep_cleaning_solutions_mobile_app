import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SRGApp());
}

// ─────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────
class AppColors {
  AppColors._();
  static const Color primary     = Color(0xFF6B3FA0);
  static const Color secondary   = Color(0xFFC0392B);
  static const Color white       = Color(0xFFFFFFFF);
  static const Color black       = Color(0xFF1A1A1A);
  static const Color bg          = Color(0xFFFFFFFF);
  static const Color surface     = Color(0xFFF5F5F5);
  static const Color textMuted   = Color(0xFF666666);
  static const Color border      = Color(0xFFEEEEEE);
  static const Color purpleLight = Color(0xFFEEEDFE);
  static const Color redLight    = Color(0xFFFEF0F0);
  static const Color green       = Color(0xFF27AE60);
  static const Color star        = Color(0xFFFFD700);
}

// ─────────────────────────────────────────
// RESPONSIVE HELPER
// ─────────────────────────────────────────
class R {
  R._();
  static double w(BuildContext ctx) => MediaQuery.sizeOf(ctx).width;
  static double h(BuildContext ctx) => MediaQuery.sizeOf(ctx).height;
  static double sp(BuildContext ctx, double size) {
    final scale = w(ctx) / 375;
    return (size * scale).clamp(size * 0.85, size * 1.2);
  }
  static double wp(BuildContext ctx, double pct) => w(ctx) * pct / 100;
}

// ─────────────────────────────────────────
// APP
// ─────────────────────────────────────────
class SRGApp extends StatelessWidget {
  const SRGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suvarnaraj Group',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

// ─────────────────────────────────────────
// MAIN SHELL
// ─────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    BlogsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined,    activeIcon: Icons.home,    label: 'Home',    index: 0, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
              _NavItem(icon: Icons.article_outlined, activeIcon: Icons.article, label: 'Blogs',   index: 1, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
              _NavItem(icon: Icons.person_outline,   activeIcon: Icons.person,  label: 'Profile', index: 2, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
            ],
          ),
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

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.current, required this.onTap});

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
              width: isActive ? 20 : 0, height: 3,
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 4),
            Icon(isActive ? activeIcon : icon, color: isActive ? AppColors.primary : AppColors.textMuted, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? AppColors.primary : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const SRGDrawer(),
      body: Builder(
        builder: (ctx) => CustomScrollView(
          slivers: [
            _SRGAppBar(ctx),
            SliverList(
              delegate: SliverChildListDelegate([
                const _BannerSection(),
                const SizedBox(height: 8),
                const _ServicesSection(),
                const SizedBox(height: 8),
                const _OurTeamSection(),
                const SizedBox(height: 8),
                const _WhyChooseUsSection(),
                const SizedBox(height: 8),
                const _HowWeWorkSection(),
                const SizedBox(height: 8),
                const _WatchInActionSection(),
                const SizedBox(height: 8),
                const _FAQSection(),
                const SizedBox(height: 20),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _SRGAppBar(BuildContext ctx) {
    return SliverAppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      pinned: true,
      leading: Builder(
        builder: (c) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.black),
          onPressed: () => Scaffold.of(c).openDrawer(),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'S', style: TextStyle(color: AppColors.primary,   fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic)),
                TextSpan(text: 'R', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic)),
                TextSpan(text: 'G', style: TextStyle(color: AppColors.primary,   fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suvarnaraj', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.black, height: 1)),
              Text('Group',      style: TextStyle(fontSize: 9, color: AppColors.textMuted, height: 1)),
            ],
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(icon: const Icon(Icons.search,                   color: AppColors.black), onPressed: () {}),
        IconButton(icon: const Icon(Icons.shopping_bag_outlined,    color: AppColors.black), onPressed: () {}),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SECTION TITLE WIDGET
// ─────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: R.sp(context, 18),
              fontWeight: FontWeight.w800,
              color: AppColors.black,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40, height: 3,
            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// BANNER SECTION
// ─────────────────────────────────────────
class _BannerSection extends StatefulWidget {
  const _BannerSection();

  @override
  State<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<_BannerSection> {
  int _current = 0;
  final PageController _ctrl = PageController();

  final List<Map<String, String>> _banners = const [
    {'tag': 'Professional Cleaning', 'title': 'Expert Cleaning\nServices for You',   'sub': 'Trusted by 1400+ happy clients across Pune'},
    {'tag': 'New Service',           'title': 'Car Wash Now\nAvailable!',             'sub': 'Book your car wash service today'},
    {'tag': 'Seasonal Offer',        'title': 'Get 20% Off\nThis Month!',             'sub': 'Limited time offer on all cleaning services'},
  ];

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
            children: List.generate(_banners.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _current == i ? 18 : 6, height: 6,
              decoration: BoxDecoration(
                color: _current == i ? AppColors.secondary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
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
        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF3A1F6E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(data['tag']!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 8),
          Text(data['title']!, style: TextStyle(color: Colors.white, fontSize: R.sp(context, 18), fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 4),
          Text(data['sub']!, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: R.sp(context, 11)), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Book Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// SERVICES SECTION — Vertical list like website
// ─────────────────────────────────────────
class _ServicesSection extends StatelessWidget {
  const _ServicesSection();

  static const List<Map<String, dynamic>> _services = [
    {'name': 'Flats',       'icon': Icons.apartment,      'color': Color(0xFFDBE4EE), 'isNew': false},
    {'name': 'Bungalows',   'icon': Icons.house,          'color': Color(0xFFE8DFF5), 'isNew': false},
    {'name': 'Offices',     'icon': Icons.business,       'color': Color(0xFFD5E8D4), 'isNew': false},
    {'name': 'Societies',   'icon': Icons.location_city,  'color': Color(0xFFDAE8FC), 'isNew': false},
    {'name': 'Restaurant',  'icon': Icons.restaurant,     'color': Color(0xFFFFE6CC), 'isNew': false},
    {'name': 'Shops',       'icon': Icons.store,          'color': Color(0xFFD5E8D4), 'isNew': false},
    {'name': 'School',      'icon': Icons.school,         'color': Color(0xFFF8D7DA), 'isNew': false},
    {'name': 'Car Wash',    'icon': Icons.directions_car, 'color': Color(0xFFE8DFF5), 'isNew': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          const _SectionTitle('Cleaning Services'),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _ServiceCard(data: _services[i]),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ServiceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final w = R.w(context) - 32;
    final imgH = w * 0.6;

    final isFlat = (data['name'] as String) == 'Flats';
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => isFlat ? const FlatCategoryScreen() : EnquiryFormScreen(serviceName: data['name'] as String),
      )),




      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: w, height: imgH,
              color: data['color'] as Color,
              child: Stack(
                children: [
                  Center(child: Icon(data['icon'] as IconData, size: 80, color: AppColors.primary.withOpacity(0.3))),
                  Positioned(
                    bottom: 12, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _OverlayBtn(icon: Icons.open_in_full),
                        const SizedBox(width: 10),
                        _OverlayBtn(icon: Icons.shopping_bag_outlined),
                      ],
                    ),
                  ),
                  if (data['isNew'] == true)
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(6)),
                        child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['name'] as String,
            style: TextStyle(fontSize: R.sp(context, 16), fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => const Icon(Icons.star, color: AppColors.star, size: 16)),
          ),
        ],
      ),
    );
  }
}

class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  const _OverlayBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
      ),
      child: Icon(icon, size: 18, color: AppColors.black),
    );
  }
}

// ─────────────────────────────────────────
// OUR TEAM SECTION
// ─────────────────────────────────────────
class _OurTeamSection extends StatelessWidget {
  const _OurTeamSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          const _SectionTitle('Our Team'),
          // Team image placeholder
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            height: R.wp(context, 55),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_rounded, size: 64, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text('Our Team Photo', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// WHY CHOOSE US — List style like website
// ─────────────────────────────────────────
class _WhyChooseUsSection extends StatelessWidget {
  const _WhyChooseUsSection();

  static const List<Map<String, dynamic>> _items = [
    {'icon': Icons.calendar_today,  'title': 'User-Friendly Booking',   'sub': 'Online Appointment Scheduling (with date/time selection)'},
    {'icon': Icons.local_offer,     'title': 'Discount Coupons & Offers','sub': 'Seasonal Cleaning Offers – Limited Time Only!'},
    {'icon': Icons.headset_mic,     'title': 'Customer Support',         'sub': 'Dedicated support'},
    {'icon': Icons.lock_outline,    'title': 'Payment Secure',           'sub': '100% secure payment'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: _items.map((item) => _WhyItem(data: item)).toList(),
      ),
    );
  }
}

class _WhyItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _WhyItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.redLight, shape: BoxShape.circle),
            child: Icon(data['icon'] as IconData, color: AppColors.secondary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] as String,
                    style: TextStyle(fontSize: R.sp(context, 14), fontWeight: FontWeight.w600, color: AppColors.black)),
                const SizedBox(height: 3),
                Text(data['sub'] as String,
                    style: TextStyle(fontSize: R.sp(context, 12), color: AppColors.textMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// HOW WE WORK — Image slider like website
// ─────────────────────────────────────────
class _HowWeWorkSection extends StatefulWidget {
  const _HowWeWorkSection();

  @override
  State<_HowWeWorkSection> createState() => _HowWeWorkSectionState();
}

class _HowWeWorkSectionState extends State<_HowWeWorkSection> {
  int _current = 0;
  final PageController _ctrl = PageController();

  static const List<Map<String, dynamic>> _items = [
    {'label': 'Kitchen Deep Cleaning', 'icon': Icons.kitchen,           'color': Color(0xFFD5E8D4)},
    {'label': 'Bedroom Cleaning',      'icon': Icons.bed,               'color': Color(0xFFE8DFF5)},
    {'label': 'Bathroom Cleaning',     'icon': Icons.bathtub,           'color': Color(0xFFDAE8FC)},
    {'label': 'Hall Cleaning',         'icon': Icons.weekend,           'color': Color(0xFFFFE6CC)},
    {'label': 'Window Cleaning',       'icon': Icons.window,            'color': Color(0xFFDBE4EE)},
    {'label': 'Floor Cleaning',        'icon': Icons.cleaning_services, 'color': Color(0xFFF8D7DA)},
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _prev() { if (_current > 0) { setState(() => _current--); _ctrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); } }
  void _next() { if (_current < _items.length - 1) { setState(() => _current++); _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); } }

  @override
  Widget build(BuildContext context) {
    final imgH = R.wp(context, 65);

    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          const _SectionTitle('How We Work'),
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
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: item['color'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Center(child: Icon(item['icon'] as IconData, size: 100, color: AppColors.primary.withOpacity(0.25))),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              ),
                              child: Text(item['label'] as String,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)]),
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
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)]),
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

// ─────────────────────────────────────────
// WATCH IN ACTION — YouTube card style
// ─────────────────────────────────────────
class _WatchInActionSection extends StatelessWidget {
  const _WatchInActionSection();

  static const List<Map<String, String>> _videos = [
    {'title': 'Hall Cleaning That Shines! | SRG Cleaning', 'channel': 'Suvarnaraj Group', 'desc': 'Our Advanced Equipments', 'sub': 'Watch how our professionals transform spaces with our comprehensive cleaning process.'},
    {'title': 'SRG – Our Cleaning Process Results',        'channel': 'Suvarnaraj Group', 'desc': 'Our Cleaning Process Results', 'sub': 'Watch how our professionals transform spaces with our comprehensive cleaning process.'},
    {'title': 'Glass Cleaning – Expert Method | SRG',      'channel': 'Suvarnaraj Group', 'desc': 'Glass Cleaning Expertise',   'sub': 'See our experts tackle the toughest glass surfaces with precision.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          const _SectionTitle('Watch Us In Action'),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _videos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _VideoCard(data: _videos[i]),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Map<String, String> data;
  const _VideoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // YouTube thumbnail style
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              width: double.infinity,
              height: R.wp(context, 55),
              color: const Color(0xFF2A2A2A),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // SRG logo top-left
                  Positioned(
                    top: 10, left: 10, right: 60,
                    child: Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Center(child: Text('SRG', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800))),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title']!, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                              Text(data['channel']!, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Play button
                  Container(
                    width: 50, height: 50,
                    decoration: const BoxDecoration(color: Color(0xFFFF0000), shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                  ),
                  // YouTube badge
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                      child: const Row(
                        children: [
                          Icon(Icons.play_circle_fill, color: Colors.white, size: 12),
                          SizedBox(width: 3),
                          Text('Watch on YouTube', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  // Link icon bottom-left
                  Positioned(
                    bottom: 8, left: 8,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.link, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Card body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['desc']!, style: TextStyle(fontSize: R.sp(context, 14), fontWeight: FontWeight.w700, color: AppColors.black)),
                const SizedBox(height: 4),
                Text(data['sub']!, style: TextStyle(fontSize: R.sp(context, 12), color: AppColors.textMuted, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('Watch More', style: TextStyle(fontSize: R.sp(context, 12), color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// FAQ SECTION — Accordion like website
// ─────────────────────────────────────────
class _FAQSection extends StatelessWidget {
  const _FAQSection();

  static const List<Map<String, String>> _faqs = [
    {'q': 'What cleaning services does Suvarnaraj Group offer?',    'a': 'Suvarnaraj Group offers a comprehensive range of cleaning services including residential cleaning, commercial cleaning, deep cleaning, move-in/move-out cleaning, post-construction cleaning, and specialized services such as carpet cleaning, upholstery cleaning, and window cleaning.'},
    {'q': 'How do I schedule a cleaning service?',                   'a': 'You can book through our app, call us at +91 7558634862, or email contact@suvarnarajgroup.com. We recommend booking 3-4 days in advance to ensure availability.'},
    {'q': 'What cleaning products and equipment do you use?',        'a': 'We use professional-grade cleaning equipment and high-quality, eco-friendly, non-toxic cleaning products that are safe for your family, pets, and the environment.'},
    {'q': 'How much does your cleaning service cost?',               'a': 'Pricing varies based on space size, type of cleaning, and frequency. Residential cleaning starts from ₹1,500 for a 1BHK apartment. Contact us for a free quote.'},
    {'q': 'Are your cleaning staff trained and insured?',            'a': 'Yes, all our professionals undergo thorough training, background checks, and we are fully insured with liability coverage.'},
    {'q': "What if I'm not satisfied with the cleaning service?",    'a': 'Customer satisfaction is our top priority. We offer a satisfaction guarantee. Notify us within 24 hours and we will arrange a follow-up cleaning at no additional cost.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          const _SectionTitle('Frequently Asked Questions'),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _faqs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _FAQItem(data: _faqs[i]),
          ),
        ],
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final Map<String, String> data;
  const _FAQItem({required this.data});
  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _open ? AppColors.secondary : AppColors.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.data['q']!,
                        style: TextStyle(fontSize: R.sp(context, 13), fontWeight: FontWeight.w600, color: _open ? AppColors.secondary : AppColors.black)),
                  ),
                  Icon(_open ? Icons.remove : Icons.add, color: _open ? AppColors.secondary : AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(widget.data['a']!, style: TextStyle(fontSize: R.sp(context, 12), color: AppColors.textMuted, height: 1.6)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// DRAWER
// ─────────────────────────────────────────
class SRGDrawer extends StatelessWidget {
  const SRGDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: AppColors.secondary, width: 2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: AppColors.purpleLight, shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2)),
                    child: const Icon(Icons.person, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rahul Sharma', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.black)),
                        SizedBox(height: 2),
                        Text('rahul@gmail.com', style: TextStyle(fontSize: 12, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _DrawerItem(icon: Icons.person_outline,         label: 'My Profile',    isActive: true, onTap: () => Navigator.pop(context)),
            _DrawerItem(icon: Icons.calendar_month_outlined, label: 'My Bookings',                  onTap: () => Navigator.pop(context)),
            const Divider(indent: 16, endIndent: 16),
            _DrawerItem(icon: Icons.phone_outlined,          label: 'Contact Us',                   onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen())); }),
            _DrawerItem(icon: Icons.language_outlined,       label: 'Visit Website',                onTap: () => Navigator.pop(context)),
            const Divider(indent: 16, endIndent: 16),
            _DrawerItem(icon: Icons.settings_outlined,       label: 'Settings',                     onTap: () => Navigator.pop(context)),
            const Spacer(),
            const Divider(indent: 16, endIndent: 16),
            _DrawerItem(icon: Icons.logout,                  label: 'Logout',       isRed: true,    onTap: () => Navigator.pop(context)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive, isRed;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.label, this.isActive = false, this.isRed = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isRed ? AppColors.secondary : isActive ? AppColors.primary : AppColors.black;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: isActive ? AppColors.purpleLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? const Border(left: BorderSide(color: AppColors.primary, width: 3)) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: color))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// CONTACT SCREEN
// ─────────────────────────────────────────
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Contact Us', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.primary,
              child: Column(
                children: [
                  const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text('Get In Touch', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text("We'd love to hear from you!", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            ),
            // Contact details
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                children: [
                  _ContactItem(icon: Icons.phone_outlined,    color: AppColors.primary,   label: 'Phone',     value: '+91 7558634862'),
                  _ContactItem(icon: Icons.email_outlined,    color: AppColors.secondary, label: 'Email',     value: 'contact@suvarnarajgroup.com'),
                  _ContactItem(icon: Icons.location_on_outlined, color: AppColors.primary, label: 'Address', value: 'Pune, Maharashtra'),
                  _ContactItem(icon: Icons.chat_outlined,     color: AppColors.green,     label: 'WhatsApp',  value: '+91 7558634862', isLast: true),
                ],
              ),
            ),
            // Message form
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Send a Message', style: TextStyle(fontSize: R.sp(context, 15), fontWeight: FontWeight.w700, color: AppColors.black)),
                  const SizedBox(height: 12),
                  _FakeInput(hint: 'Your Name'),
                  const SizedBox(height: 10),
                  _FakeInput(hint: 'Your Email'),
                  const SizedBox(height: 10),
                  _FakeInput(hint: 'Phone Number'),
                  const SizedBox(height: 10),
                  _FakeInput(hint: 'Your Message...', maxLines: 4),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Send Message', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final bool isLast;

  const _ContactItem({required this.icon, required this.color, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, color: AppColors.black, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FakeInput extends StatelessWidget {
  final String hint;
  final int maxLines;
  const _FakeInput({required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true, fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────
// BLOGS SCREEN
// ─────────────────────────────────────────
class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});
  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  int _selectedCategory = 0;
  final List<String> _categories = ['All Posts', 'Cleaning', 'Tips', 'Home Care'];

  static const List<Map<String, dynamic>> _blogs = [
    {'category': 'Cleaning',  'title': 'How to Choose the Right Office Cleaning Company: A Complete Guide',             'desc': 'A clean office is not just about looks. It directly affects employee health, productivity, and your company\'s profession...', 'icon': '🏢', 'color': 0xFFD5E8D4},
    {'category': 'Cleaning',  'title': 'Cleaning Standards for Corporate Offices in Pune: Why Deep Cleaning Is Essential','desc': 'Cleanliness as a Corporate Priority in Pune has emerged as one of India\'s most important corporate and IT hubs...',          'icon': '🏙️', 'color': 0xFFDAE8FC},
    {'category': 'Home Care', 'title': 'How to Maintain Home Cleanliness After the Monsoon',                             'desc': 'The monsoon season brings relief from heat, but once the rains stop, they often leave behind dampness, dirt, and hidden...', 'icon': '🏠', 'color': 0xFFE8DFF5},
    {'category': 'Tips',      'title': '5 Easy Ways to Keep Your Kitchen Spotless Every Day',                            'desc': 'The kitchen is the heart of every home. Keeping it clean not only ensures hygiene but also makes cooking more enjoyable...',  'icon': '🍳', 'color': 0xFFFFE6CC},
    {'category': 'Cleaning',  'title': 'Why Professional Bathroom Cleaning is Better Than DIY',                          'desc': 'Bathrooms are breeding grounds for germs and bacteria. Professional cleaning ensures deep sanitization that regular...',       'icon': '🚿', 'color': 0xFFDBE4EE},
    {'category': 'Tips',      'title': 'Top 7 Signs You Need a Deep Cleaning Service Right Now',                         'desc': 'Most people clean their homes regularly, but there are times when a regular clean just isn\'t enough. Here are signs...',    'icon': '✨', 'color': 0xFFF8D7DA},
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_selectedCategory == 0) return _blogs;
    final cat = _categories[_selectedCategory];
    return _blogs.where((b) => b['category'] == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const SRGDrawer(),
      body: Builder(
        builder: (ctx) => CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              backgroundColor: AppColors.white,
              elevation: 0, pinned: true,
              leading: Builder(
                builder: (c) => IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.black),
                  onPressed: () => Scaffold.of(c).openDrawer(),
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(text: const TextSpan(children: [
                    TextSpan(text: 'S', style: TextStyle(color: AppColors.primary,   fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic)),
                    TextSpan(text: 'R', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic)),
                    TextSpan(text: 'G', style: TextStyle(color: AppColors.primary,   fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic)),
                  ])),
                  const SizedBox(width: 4),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Suvarnaraj', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.black, height: 1)),
                    Text('Group',      style: TextStyle(fontSize: 9, color: AppColors.textMuted, height: 1)),
                  ]),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(icon: const Icon(Icons.search,               color: AppColors.black), onPressed: () {}),
                IconButton(icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.black), onPressed: () {}),
              ],
              bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
            ),

            SliverList(
              delegate: SliverChildListDelegate([
                // Hero
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF9B59B6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: Column(
                    children: [
                      Text('Our Blog', style: TextStyle(color: Colors.white, fontSize: R.sp(context, 24), fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text('Discover tips, insights, and stories about cleaning services',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: R.sp(context, 13), height: 1.4)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Category filter
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final isActive = _selectedCategory == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.secondary : AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isActive ? AppColors.secondary : AppColors.border),
                          ),
                          child: Text(_categories[i],
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.black)),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Blog list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _BlogCard(data: _filtered[i]),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BlogCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = Color(data['color'] as int);
    final imgH  = R.wp(context, 55);

    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity, height: imgH, color: color,
                    child: Center(child: Text(data['icon'] as String, style: const TextStyle(fontSize: 64))),
                  ),
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(4)),
                      child: Text((data['category'] as String).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] as String,
                      style: TextStyle(fontSize: R.sp(context, 15), fontWeight: FontWeight.w700, color: AppColors.black, height: 1.35),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(data['desc'] as String,
                      style: TextStyle(fontSize: R.sp(context, 12), color: AppColors.textMuted, height: 1.5),
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('READ MORE',
                          style: TextStyle(fontSize: R.sp(context, 12), color: AppColors.black, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 14, color: AppColors.black),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// PROFILE SCREEN
// ─────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const SRGDrawer(),
      body: Builder(
        builder: (ctx) => CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.white,
              elevation: 0, pinned: true,
              leading: Builder(
                builder: (c) => IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.black),
                  onPressed: () => Scaffold.of(c).openDrawer(),
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(text: const TextSpan(children: [
                    TextSpan(text: 'S', style: TextStyle(color: AppColors.primary,   fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic)),
                    TextSpan(text: 'R', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic)),
                    TextSpan(text: 'G', style: TextStyle(color: AppColors.primary,   fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic)),
                  ])),
                  const SizedBox(width: 4),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Suvarnaraj', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.black, height: 1)),
                    Text('Group',      style: TextStyle(fontSize: 9, color: AppColors.textMuted, height: 1)),
                  ]),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(icon: const Icon(Icons.search,                color: AppColors.black), onPressed: () {}),
                IconButton(icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.black), onPressed: () {}),
              ],
              bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
            ),

            SliverList(
              delegate: SliverChildListDelegate([
                // Hero
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
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                          color: Colors.white.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 14),
                      Text('Welcome back,\nvijayatest!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: R.sp(context, 22), fontWeight: FontWeight.w800, height: 1.3)),
                      const SizedBox(height: 8),
                      Text('Manage your account and track your cleaning services',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.secondary, fontSize: R.sp(context, 13), height: 1.4)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Menu
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      _ProfileMenuItem(icon: Icons.person_outline,  label: 'My Profile',      isActive: true,               onTap: () {}),
                      _ProfileMenuItem(icon: Icons.receipt_long,     label: 'My Orders',                                     onTap: () {}),
                      _ProfileMenuItem(icon: Icons.favorite_outline, label: 'Wishlist',                                      onTap: () {}),
                      _ProfileMenuItem(icon: Icons.lock_outline,     label: 'Change Password',                               onTap: () {}),
                      _ProfileMenuItem(icon: Icons.logout,           label: 'Logout',          isRed: true, isLast: true,    onTap: () {}),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive, isRed, isLast;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isRed    = false,
    this.isLast   = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRed ? AppColors.secondary : isActive ? AppColors.secondary : AppColors.black;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isActive ? AppColors.redLight : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive ? const Border(left: BorderSide(color: AppColors.secondary, width: 3)) : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: TextStyle(fontSize: R.sp(context, 14),
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: color)),
                ),
                if (!isRed)
                  Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
          if (!isLast)
            Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// ENQUIRY FORM SCREEN
// ─────────────────────────────────────────
class EnquiryFormScreen extends StatefulWidget {
  final String serviceName;
  const EnquiryFormScreen({super.key, required this.serviceName});

  @override
  State<EnquiryFormScreen> createState() => _EnquiryFormScreenState();
}

class _EnquiryFormScreenState extends State<EnquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _mobileCtrl     = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _stateCtrl      = TextEditingController();
  final _cityCtrl       = TextEditingController();
  final _areaCtrl       = TextEditingController();

  String? _selectedService;
  String? _selectedTime;
  DateTime? _selectedDate;
  bool _orderInspection = false;

  final List<String> _services = [
    'Flat Cleaning', 'Bungalow Cleaning', 'Office Cleaning',
    'Society Cleaning', 'Restaurant Cleaning', 'Shop Cleaning',
    'School Cleaning', 'Car Wash',
  ];

  final List<String> _timeSlots = [
    '10:00 AM', '11:00 AM', '12:00 PM',
    '1:00 PM',  '2:00 PM',  '3:00 PM',
    '4:00 PM',  '5:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedService = widget.serviceName.contains('Flat') ? 'Flat Cleaning'
        : widget.serviceName.contains('Bungalow') ? 'Bungalow Cleaning'
        : widget.serviceName.contains('Office')   ? 'Office Cleaning'
        : widget.serviceName.contains('Society')  ? 'Society Cleaning'
        : widget.serviceName.contains('Restaurant') ? 'Restaurant Cleaning'
        : widget.serviceName.contains('Shop')     ? 'Shop Cleaning'
        : widget.serviceName.contains('School')   ? 'School Cleaning'
        : widget.serviceName.contains('Car')      ? 'Car Wash'
        : null;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _emailCtrl.dispose();     _mobileCtrl.dispose();
    _addressCtrl.dispose();   _stateCtrl.dispose();
    _cityCtrl.dispose();      _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Submit an Enquiry',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Name Row ──────────────────────
              Row(
                children: [
                  Expanded(child: _FormField(ctrl: _firstNameCtrl, hint: 'First Name', validator: (v) => v!.isEmpty ? 'Required' : null)),
                  const SizedBox(width: 10),
                  Expanded(child: _FormField(ctrl: _lastNameCtrl,  hint: 'Last Name',  validator: (v) => v!.isEmpty ? 'Required' : null)),
                ],
              ),
              const SizedBox(height: 10),

              // ── Email & Mobile ─────────────────
              Row(
                children: [
                  Expanded(child: _FormField(ctrl: _emailCtrl,  hint: 'Email',             keyboardType: TextInputType.emailAddress)),
                  const SizedBox(width: 10),
                  Expanded(child: _FormField(ctrl: _mobileCtrl, hint: 'Mobile (10 digits)', keyboardType: TextInputType.phone,
                      validator: (v) => v!.length != 10 ? '10 digits required' : null)),
                ],
              ),
              const SizedBox(height: 10),

              // ── Address ────────────────────────
              _FormField(ctrl: _addressCtrl, hint: 'Address', maxLines: 2),
              const SizedBox(height: 10),

              // ── State & City ───────────────────
              Row(
                children: [
                  Expanded(child: _FormField(ctrl: _stateCtrl, hint: 'State')),
                  const SizedBox(width: 10),
                  Expanded(child: _FormField(ctrl: _cityCtrl,  hint: 'City')),
                ],
              ),
              const SizedBox(height: 10),

              // ── Service Dropdown ───────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedService,
                    hint: const Text('Choose Service', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                    items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _selectedService = v),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Total Area ─────────────────────
              const Text('Total Area in Sq. Ft. (if known)',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _FormField(ctrl: _areaCtrl, hint: '', keyboardType: TextInputType.number),
              const SizedBox(height: 14),

              // ── Inspection Checkbox ────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _orderInspection ? AppColors.primary : AppColors.border),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _orderInspection,
                          onChanged: (v) => setState(() => _orderInspection = v!),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        const Expanded(
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: 'Order inspection at just Rs 200/- ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black)),
                            TextSpan(text: '*', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                          ])),
                        ),
                      ],
                    ),
                    if (_orderInspection) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFE082)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Color(0xFF795548)),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Note: You will be redirected to PhonePe payment gateway to complete the Rs 200 payment for inspection scheduling.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF795548), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Schedule Inspection ────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4), style: BorderStyle.solid),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Schedule Your Inspection',
                            style: TextStyle(fontSize: R.sp(context, 14), fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Date picker
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Inspection Date *',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedDate != null ? _formatDate(_selectedDate!) : 'dd/mm/yyyy',
                                          style: TextStyle(fontSize: 13, color: _selectedDate != null ? AppColors.black : AppColors.textMuted),
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('You can select dates starting from tomorrow',
                                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Time picker
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Inspection Time *',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedTime,
                                    hint: const Text('Select Time', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
                                    items: _timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                                    onChanged: (v) => setState(() => _selectedTime = v),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Available between 10:00 AM - 5:00 PM',
                                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Submit Button ──────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Enquiry submitted successfully!'),
                          backgroundColor: AppColors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    _orderInspection ? 'Proceed to Payment (Rs 200)' : 'Submit Enquiry',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Form Field Widget ──────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.ctrl,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: AppColors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true, fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.secondary)),
      ),
    );
  }
}

// ─────────────────────────────────────────
// FLAT CATEGORY SCREEN
// ─────────────────────────────────────────
class FlatCategoryScreen extends StatelessWidget {
  const FlatCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Flat Cleaning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text('Select Your Flat Category',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: R.sp(context, 20), fontWeight: FontWeight.w800, color: AppColors.black)),
            const SizedBox(height: 20),
            // Furnished / Unfurnished
            Column(
              children: [
                _FlatCategoryCard(
                  title: 'Furnished Flats',
                  color: const Color(0xFFE8DFF5),
                  icon: Icons.chair_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const BHKListScreen(type: 'Furnished'),
                  )),
                ),
                const SizedBox(height: 16),
                _FlatCategoryCard(
                  title: 'Unfurnished Flats',
                  color: const Color(0xFFDBE4EE),
                  icon: Icons.home_outlined,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const BHKListScreen(type: 'Unfurnished'),
                  )),
                ),
              ],
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
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _FlatCategoryCard({required this.title, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: R.wp(context, 62),
              width: double.infinity,
              color: color,
              child: Center(child: Icon(icon, size: 100, color: AppColors.primary.withOpacity(0.4))),
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: R.sp(context, 15), fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            child: const Text('EXPLORE NOW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// BHK LIST SCREEN
// ─────────────────────────────────────────
class BHKListScreen extends StatelessWidget {
  final String type; // 'Furnished' or 'Unfurnished'
  const BHKListScreen({super.key, required this.type});

  static const List<Map<String, dynamic>> _bhkList = [
    {'name': '1 BHK', 'color': Color(0xFFE8F5E9)},
    {'name': '2 BHK', 'color': Color(0xFFE3F2FD)},
    {'name': '3 BHK', 'color': Color(0xFFF3E5F5)},
    {'name': '4 BHK', 'color': Color(0xFFFFF3E0)},
    {'name': '5 BHK', 'color': Color(0xFFFFEBEE)},
  ];

  static final Map<String, dynamic> _services = {
    'Furnished': {
      '1 BHK': [
        {'title': 'Hall Cleaning',     'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Cabinets Cleaning (Inside & Outside), Fans/AC, Floor Scrubbing & Mopping, Tables/Chairs/Lamp/Frames/TV set etc.'},
        {'title': 'Bedroom Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Cabinets Cleaning (Inside & Outside), Fans/AC, Floor Scrubbing & Mopping, Bed (Inside/Outside)'},
        {'title': 'Kitchen Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans, Floor Scrubbing & Mopping, Chimney/Stove (Exterior), Cabinets & Trolly Cleaning (Inside & Outside, Steam Cleaner)'},
        {'title': 'Bathroom Cleaning', 'desc': 'Commode Pot Cleaning, Shower, Taps, Exhaust (WetWiping), Hard Stain Removal, Drill Brush Scrubbing, Sink Cleaning, Mirrors/Glass wiping'},
        {'title': 'Balcony Cleaning',  'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
      ],
      '2 BHK': [
        {'title': 'Hall Cleaning',     'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Cabinets Cleaning (Inside & Outside), Fans/AC, Floor Scrubbing & Mopping'},
        {'title': 'Bedroom Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Cabinets (Inside & Outside), Fans/AC, Floor Scrubbing, Bed (Inside/Outside) — 2 Bedrooms'},
        {'title': 'Kitchen Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans, Floor Scrubbing & Mopping, Chimney/Stove (Exterior), Steam Cleaner'},
        {'title': 'Bathroom Cleaning', 'desc': 'Commode Pot Cleaning, Shower, Taps, Exhaust (WetWiping), Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 2 Bathrooms'},
        {'title': 'Balcony Cleaning',  'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
      ],
      '3 BHK': [
        {'title': 'Hall Cleaning',     'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing & Mopping, Tables/Chairs/Lamp/Frames/TV set etc.'},
        {'title': 'Bedroom Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing, Bed (Inside/Outside) — 3 Bedrooms'},
        {'title': 'Kitchen Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans, Floor Scrubbing, Chimney/Stove (Exterior), Cabinets & Trolly (Steam Cleaner)'},
        {'title': 'Bathroom Cleaning', 'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 3 Bathrooms'},
        {'title': 'Balcony Cleaning',  'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
      ],
      '4 BHK': [
        {'title': 'Hall Cleaning',     'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing & Mopping'},
        {'title': 'Bedroom Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing, Bed (Inside/Outside) — 4 Bedrooms'},
        {'title': 'Kitchen Cleaning',  'desc': 'Dry Dusting, Vacuuming, Fans, Floor Scrubbing, Chimney/Stove (Exterior), Cabinets & Trolly (Steam Cleaner)'},
        {'title': 'Bathroom Cleaning', 'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 4 Bathrooms'},
        {'title': 'Balcony Cleaning',  'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
      ],
      '5 BHK': [
        {'title': 'Hall Cleaning',     'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing & Mopping'},
        {'title': 'Bedroom Cleaning',  'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing, Bed (Inside/Outside) — 5 Bedrooms'},
        {'title': 'Kitchen Cleaning',  'desc': 'Dry Dusting, Vacuuming, Fans, Floor Scrubbing, Chimney/Stove (Exterior), Cabinets & Trolly (Steam Cleaner)'},
        {'title': 'Bathroom Cleaning', 'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 5 Bathrooms'},
        {'title': 'Balcony Cleaning',  'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
      ],
    },
    'Unfurnished': {
      '1 BHK': [
        {'title': 'Hall & Bedroom Cleaning', 'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Cabinets Cleaning (Outside), Fans/AC, Floor Scrubbing & Mopping'},
        {'title': 'Kitchen Cleaning',        'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans, Floor Scrubbing & Mopping, Chimney/Stove (Exterior Cleaning)'},
        {'title': 'Bathroom Cleaning',       'desc': 'Commode Pot Cleaning, Shower, Taps, Exhaust (WetWiping), Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping'},
        {'title': 'Balcony Cleaning',        'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
      ],
      '2 BHK': [
        {'title': 'Hall & Bedroom Cleaning', 'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Cabinets Cleaning (Outside), Fans/AC, Floor Scrubbing & Mopping — 2 Bedrooms'},
        {'title': 'Kitchen Cleaning',        'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans, Floor Scrubbing & Mopping, Chimney/Stove (Exterior Cleaning)'},
        {'title': 'Bathroom Cleaning',       'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 2 Bathrooms'},
        {'title': 'Balcony Cleaning',        'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
      ],
      '3 BHK': [
        {'title': 'Hall & Bedroom Cleaning', 'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing & Mopping — 3 Bedrooms'},
        {'title': 'Kitchen Cleaning',        'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans, Floor Scrubbing, Chimney/Stove (Exterior Cleaning)'},
        {'title': 'Bathroom Cleaning',       'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 3 Bathrooms'},
        {'title': 'Balcony Cleaning',        'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
      ],
      '4 BHK': [
        {'title': 'Hall & Bedroom Cleaning', 'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing & Mopping — 4 Bedrooms'},
        {'title': 'Kitchen Cleaning',        'desc': 'Dry Dusting, Vacuuming, Fans, Floor Scrubbing, Chimney/Stove (Exterior Cleaning)'},
        {'title': 'Bathroom Cleaning',       'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 4 Bathrooms'},
        {'title': 'Balcony Cleaning',        'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
      ],
      '5 BHK': [
        {'title': 'Hall & Bedroom Cleaning', 'desc': 'Dry Dusting, Vacuuming, Wet Wiping, Fans/AC, Floor Scrubbing & Mopping — 5 Bedrooms'},
        {'title': 'Kitchen Cleaning',        'desc': 'Dry Dusting, Vacuuming, Fans, Floor Scrubbing, Chimney/Stove (Exterior Cleaning)'},
        {'title': 'Bathroom Cleaning',       'desc': 'Commode Pot Cleaning, Shower, Taps, Hard Stain Removal, Sink Cleaning, Mirrors/Glass wiping — 5 Bathrooms'},
        {'title': 'Balcony Cleaning',        'desc': 'Dry Dusting, Vacuuming, Floor Scrubbing'},
      ],
    },
  };

  List<Map<String, String>> _getServices(String bhk) {
    final typeMap = _services[type] as Map<String, dynamic>?;
    final list = typeMap?[bhk] ?? typeMap?["1 BHK"] ?? [];
    return (list as List).map((e) => Map<String, String>.from(e as Map)).toList();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.black), onPressed: () => Navigator.pop(context)),
        title: Text('$type Flats', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bhkList.length,
              itemBuilder: (_, i) {
                final bhk = _bhkList[i];
                final bhkName = bhk['name'] as String;
                final fullName = '$bhkName $type Homes';
                final imgH = R.wp(context, 60);
                return GestureDetector(
                  onTap: () => _showServiceBottomSheet(context, fullName, _getServices(bhkName)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: imgH,
                                width: double.infinity,
                                color: bhk['color'] as Color,
                                child: Center(child: Icon(
                                  type == 'Furnished' ? Icons.chair_rounded : Icons.home_outlined,
                                  size: 100, color: AppColors.primary.withOpacity(0.25),
                                )),
                              ),
                            ),
                            Positioned(
                              top: 10, left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(5)),
                                child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(fullName,
                            style: TextStyle(fontSize: R.sp(context, 15), fontWeight: FontWeight.w600, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (_) => const Icon(Icons.star, color: AppColors.star, size: 15)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showServiceBottomSheet(BuildContext context, String title, List<Map<String, String>> services) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceDetailSheet(title: title, services: services),
    );
  }
}

// ─────────────────────────────────────────
// SERVICE DETAIL BOTTOM SHEET
// ─────────────────────────────────────────
class _ServiceDetailSheet extends StatefulWidget {
  final String title;
  final List<Map<String, String>> services;
  const _ServiceDetailSheet({required this.title, required this.services});

  @override
  State<_ServiceDetailSheet> createState() => _ServiceDetailSheetState();
}

class _ServiceDetailSheetState extends State<_ServiceDetailSheet> {
  final _sqftCtrl = TextEditingController();
  bool _cleanWalls    = false;
  bool _cleanPaint    = false;
  bool _removeCover   = false;

  @override
  void dispose() { _sqftCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: TextStyle(fontSize: R.sp(context, 16), fontWeight: FontWeight.w800, color: AppColors.black)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.shopping_cart, size: 14),
                    label: const Text('ADD TO CART', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textMuted, size: 22),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  // Sq.ft input
                  RichText(text: const TextSpan(children: [
                    TextSpan(text: 'How much sq.ft. is your property? ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black)),
                    TextSpan(text: '*', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 13)),
                  ])),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _sqftCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter sq.ft.',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true, fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Checkboxes
                  _CheckItem(label: 'Do you want to clean walls and ceilings?',               value: _cleanWalls,  onChanged: (v) => setState(() => _cleanWalls  = v!)),
                  _CheckItem(label: 'Do you want to clean paint and adhesive stains?',          value: _cleanPaint,  onChanged: (v) => setState(() => _cleanPaint  = v!)),
                  _CheckItem(label: 'Do you want protective film/plastic cover removed from furniture?', value: _removeCover, onChanged: (v) => setState(() => _removeCover = v!)),

                  const SizedBox(height: 16),
                  Divider(color: AppColors.border),
                  const SizedBox(height: 8),

                  // Services Included
                  const Text('Services Included:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.black)),
                  const SizedBox(height: 12),

                  ...widget.services.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(text: '${s['title']} : ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black)),
                        TextSpan(text: s['desc'], style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5)),
                      ]),
                    ),
                  )),

                  const SizedBox(height: 16),
                  Divider(color: AppColors.border),
                  const SizedBox(height: 12),

                  // Add to cart bottom
                  SizedBox(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${widget.title} added to cart!'),
                          backgroundColor: AppColors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ));
                      },
                      icon: const Icon(Icons.shopping_cart, size: 16),
                      label: const Text('ADD TO CART', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckItem({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24, height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.black)),
          ),
        ),
      ],
    );
  }
}