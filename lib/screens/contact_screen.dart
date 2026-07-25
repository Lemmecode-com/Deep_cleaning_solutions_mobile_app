// lib/screens/contact_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/providers/auth_provider.dart';
import 'package:dcs_app/services/contact_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _mobileCtrl  = TextEditingController();
  final _serviceCtrl = TextEditingController();
  final _msgCtrl     = TextEditingController();
  bool _isLoading    = false;

  final ContactService _contactService = ContactService();

  // ✅ FIX: services list आता website (deepcleaningsolutions.in) च्या
  // dropdown प्रमाणे exact match करते.
  final List<String> _services = [
    'Choose the service',
    'Custom Home Cleaning',
    'Flats Cleaning (Furnished & Unfurnished)',
    'Bungalows Cleaning',
    'Offices Cleaning',
    'Societies Cleaning',
    'Restaurant Cleaning',
    'Shops Cleaning',
    'School/Colleges Cleaning',
    'Car Wash',
    'Other',
  ];
  String? _selectedService;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _nameCtrl.text   = (user['name']   ?? '').toString();
        _emailCtrl.text  = (user['email']  ?? '').toString();
        _mobileCtrl.text = (user['mobile'] ?? user['phone'] ?? '').toString();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _serviceCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _contactService.sendMessage(
        name:    _nameCtrl.text.trim(),
        email:   _emailCtrl.text.trim(),
        mobile:  _mobileCtrl.text.trim(),
        service: _selectedService ?? _serviceCtrl.text.trim(),
        message: _msgCtrl.text.trim(),
      );
      if (mounted) {
        // ✅ FIX: सक्सेसफुल submit नंतर सगळे fields clear होतात —
        // आधी फक्त message clear व्हायचा, आता Name, Email, Mobile,
        // Service dropdown आणि Message सगळं reset होतं.
        _nameCtrl.clear();
        _emailCtrl.clear();
        _mobileCtrl.clear();
        _serviceCtrl.clear();
        _msgCtrl.clear();
        setState(() => _selectedService = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message sent successfully!'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
        title: const Text(
          'Contact Us',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // ── Send Message Form ──────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SEND MESSAGE',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                    _InputField(ctrl: _nameCtrl,   hint: 'Name',    validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 10),
                    _InputField(ctrl: _emailCtrl,  hint: 'Email',   keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 10),
                    _InputField(ctrl: _mobileCtrl, hint: 'Mobile',  keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 10),

                    // ✅ FIX: Service dropdown आता mandatory आहे.
                    // काहीही निवडलं नाही तर form submit होणार नाही आणि
                    // "Please choose a service" असा red error दिसेल.
                    FormField<String>(
                      initialValue: _selectedService,
                      validator: (v) => (v == null || v.isEmpty) ? 'Please choose a service' : null,
                      builder: (field) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: field.hasError ? AppColors.secondary : AppColors.border,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedService,
                                  hint: const Text('Choose the service', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                                  items: _services
                                      .where((s) => s != 'Choose the service') // placeholder हा actual option नाही
                                      .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s, style: const TextStyle(fontSize: 13)),
                                  ))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() => _selectedService = v);
                                    field.didChange(v);
                                  },
                                ),
                              ),
                            ),
                            if (field.hasError)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 4),
                                child: Text(
                                  field.errorText!,
                                  style: const TextStyle(color: AppColors.secondary, fontSize: 11),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                    _InputField(ctrl: _msgCtrl, hint: 'Message', maxLines: 4, validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('SEND MESSAGE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Contact Info ───────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONTACT INFO',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  _ContactItem(
                    icon: Icons.location_on,
                    color: AppColors.secondary,
                    label: 'Address',
                    value: 'Shop no.3, Rajdhani Complex, Near Shankar Maharaj Math, Balaji Nagar, Pune, Maharashtra 411043',
                    onTap: () => _launchUrl('https://maps.google.com/?q=Shop+no.3+Rajdhani+Complex+Balaji+Nagar+Pune+Maharashtra+411043'),
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  _ContactItem(
                    icon: Icons.phone,
                    color: AppColors.primary,
                    label: 'Phone',
                    value: '+91 8485854972',
                    onTap: () => _launchUrl('tel:+918485854972'),
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  _ContactItem(
                    icon: Icons.email,
                    color: AppColors.primary,
                    label: 'Support',
                    value: 'contact@deepcleaningsolutions.in',
                    onTap: () => _launchUrl('mailto:contact@deepcleaningsolutions.in'),
                  ),
                ],
              ),
            ),

            // ── Map Section ────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  // Map Placeholder
                  GestureDetector(
                    onTap: () => _launchUrl(
                      'https://maps.google.com/?q=Shop+no.3+Rajdhani+Complex+Balaji+Nagar+Pune+Maharashtra+411043',
                    ),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: const Color(0xFFE8F0FE),
                      child: Stack(
                        children: [
                          // Grid painter
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _MapGridPainter(),
                            ),
                          ),
                          // Location pin + label
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on, color: AppColors.secondary, size: 14),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Deep Cleaning Solutions',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Icon(Icons.location_on, color: AppColors.secondary, size: 40),
                              ],
                            ),
                          ),
                          // Open in Maps hint
                          Positioned(
                            bottom: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.open_in_new, size: 11, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Open in Maps',
                                    style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Get Directions Button
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _launchUrl(
                          'https://maps.google.com/?q=Shop+no.3+Rajdhani+Complex+Balaji+Nagar+Pune+Maharashtra+411043',
                        ),
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: const Text(
                          'Open in Maps',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
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

// ── Map Grid Painter ───────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFCCDBF5)
      ..strokeWidth = 0.8;

    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.45), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7),  Offset(size.width, size.height * 0.7),  roadPaint);
    canvas.drawLine(Offset(size.width * 0.35, 0),  Offset(size.width * 0.35, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.65, 0),  Offset(size.width * 0.65, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Contact Item ───────────────────────────────────────────────────────
class _ContactItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final VoidCallback? onTap;

  const _ContactItem({required this.icon, required this.color, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input Field ────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _InputField({required this.ctrl, required this.hint, this.maxLines = 1, this.keyboardType, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.surface,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.secondary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}