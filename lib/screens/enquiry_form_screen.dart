// lib/screens/enquiry_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/providers/auth_provider.dart';
import 'package:dcs_app/services/enquiry_service.dart';
import 'package:dcs_app/widgets/terms_checkbox.dart';

class EnquiryFormScreen extends ConsumerStatefulWidget {
  final String serviceName;
  const EnquiryFormScreen({super.key, required this.serviceName});

  @override
  ConsumerState<EnquiryFormScreen> createState() => _EnquiryFormScreenState();
}

class _EnquiryFormScreenState extends ConsumerState<EnquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _mobileCtrl    = TextEditingController();
  final _addressCtrl   = TextEditingController();
  final _stateCtrl     = TextEditingController();
  final _cityCtrl      = TextEditingController();

  String? _selectedService;
  String? _selectedTime;
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _orderInspection = false;

  // ✅ NEW: mandatory Terms & Conditions / Privacy Policy agreement
  bool _agreedToTerms = false;

  final EnquiryService _enquiryService = EnquiryService();

  // ✅ simple email format check
  final RegExp _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\-\.]+$');

  // ✅ FIX: Car Wash service अजून launch झालेली नाही, म्हणून dropdown मधून
  // कायमचा काढून टाकला. आणि 'Choose Service' हा dummy item इथे नाहीये —
  // तो फक्त dropdown चा `hint` म्हणून खाली दाखवला जातो (value == null असताना).
  final List<String> _services = [
    'Bungalow Cleaning',
    'Office Cleaning',
    'Societies Cleaning',
    'Restaurant Cleaning',
    'Shops Cleaning',
    'School/Collegs Cleaning',
  ];

  final List<Map<String, String>> _timeSlots = [
    {'label': '10:00 AM', 'value': '10:00'},
    {'label': '10:30 AM', 'value': '10:30'},
    {'label': '11:00 AM', 'value': '11:00'},
    {'label': '11:30 AM', 'value': '11:30'},
    {'label': '12:00 PM', 'value': '12:00'},
    {'label': '12:30 PM', 'value': '12:30'},
    {'label': '1:00 PM',  'value': '13:00'},
    {'label': '1:30 PM', 'value': '13:30'},
    {'label': '2:00 PM',  'value': '14:00'},
    {'label': '2:30 PM', 'value': '14:30'},
    {'label': '3:00 PM',  'value': '15:00'},
    {'label': '3:30 PM', 'value': '15:30'},
    {'label': '4:00 PM',  'value': '16:00'},
    {'label': '4:30 PM', 'value': '16:30'},
    {'label': '5:00 PM',  'value': '17:00'},
  ];

  @override
  void initState() {
    super.initState();

    // ✅ FIX: आता service auto-select होत नाही. यूजरने manually dropdown मधून
    // service निवडलीच पाहिजे. Dropdown value null असल्यामुळे खाली
    // 'Choose Service' hint आपोआप दिसेल.
    _selectedService = null;

    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null) {
        final name = (user['name'] ?? '').toString().split(' ');
        _firstNameCtrl.text = name.isNotEmpty ? name[0] : '';
        _lastNameCtrl.text  = name.length > 1 ? name.sublist(1).join(' ') : '';
        _emailCtrl.text     = (user['email']  ?? '').toString();
        _mobileCtrl.text    = (user['mobile'] ?? user['phone'] ?? '').toString();
      }
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _stateCtrl.dispose();
    _cityCtrl.dispose();
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

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatDateForApi(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ FIX: service निवडलीच पाहिजे — null असेल (म्हणजे अजूनही
    // 'Choose Service' दाखवत असेल) तर पुढे जाऊ देऊ नये.
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service'), backgroundColor: AppColors.secondary),
      );
      return;
    }

    // ✅ FIX: "Order inspection at just Rs 200/-" checkbox आता compulsory आहे —
    // तो check केल्याशिवाय फॉर्म submit होणार नाही.
    if (!_orderInspection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check "Order inspection" to proceed'), backgroundColor: AppColors.secondary),
      );
      return;
    }

    // ✅ NEW: block enquiry submission until Terms & Privacy Policy are accepted
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms & Conditions and Privacy Policy'), backgroundColor: AppColors.secondary),
      );
      return;
    }

    // ✅ FIX: checkbox compulsory असल्यामुळे date & time पण compulsory —
    // previously these were never checked, so a user could tap "Proceed to
    // Payment" with no date/time chosen and inspectionDate/inspectionTime
    // would silently go to the API as null.
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select inspection date'), backgroundColor: AppColors.secondary),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select inspection time'), backgroundColor: AppColors.secondary),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ FIX: serviceType → service, order_inspection काढला
      final response = await _enquiryService.submitEnquiry(
        firstName:      _firstNameCtrl.text.trim(),
        lastName:       _lastNameCtrl.text.trim(),
        email:          _emailCtrl.text.trim(),
        mobile:         _mobileCtrl.text.trim(),
        address:        _addressCtrl.text.trim(),
        state:          _stateCtrl.text.trim(),
        city:           _cityCtrl.text.trim(),
        service:        _selectedService!,
        orderInspection: _orderInspection,
        inspectionDate: _selectedDate != null ? _formatDateForApi(_selectedDate!) : null,
        inspectionTime: _selectedTime,
      );

      if (mounted) {
        // ✅ API response मध्ये redirect_url येतो — PhonePe payment साठी
        final redirectUrl = response['data']?['redirect_url'];
        if (redirectUrl != null && redirectUrl.toString().isNotEmpty) {
          final uri = Uri.parse(redirectUrl.toString());
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Enquiry submitted successfully!'),
              backgroundColor: AppColors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context);
        }
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
        title: const Text('Submit an Enquiry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black)),
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
              Row(children: [
                Expanded(child: _FormField(ctrl: _firstNameCtrl, hint: 'First Name', validator: (v) => v!.isEmpty ? 'Required' : null)),
                const SizedBox(width: 10),
                Expanded(child: _FormField(ctrl: _lastNameCtrl,  hint: 'Last Name',  validator: (v) => v!.isEmpty ? 'Required' : null)),
              ]),
              const SizedBox(height: 10),

              // ── Email & Mobile ─────────────────
              // ✅ FIX: email was not required and had no format check
              Row(children: [
                Expanded(child: _FormField(
                  ctrl: _emailCtrl,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!_emailRegex.hasMatch(v.trim())) return 'Invalid email';
                    return null;
                  },
                )),
                const SizedBox(width: 10),
                Expanded(child: _FormField(ctrl: _mobileCtrl, hint: 'Mobile (10 digits)', keyboardType: TextInputType.phone, validator: (v) => v!.length != 10 ? '10 digits required' : null)),
              ]),
              const SizedBox(height: 10),

              // ── Address ────────────────────────
              // ✅ FIX: address was not required
              _FormField(ctrl: _addressCtrl, hint: 'Address', maxLines: 2, validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 10),

              // ── State & City ───────────────────
              Row(children: [
                Expanded(child: _FormField(ctrl: _stateCtrl, hint: 'State', validator: (v) => v!.trim().isEmpty ? 'Required' : null)),
                const SizedBox(width: 10),
                Expanded(child: _FormField(ctrl: _cityCtrl,  hint: 'City', validator: (v) => v!.trim().isEmpty ? 'Required' : null)),
              ]),
              const SizedBox(height: 10),

              // ── Service Dropdown ───────────────
              // ✅ FIX: 'service' field (आधी service_type होता).
              // value == null असल्यामुळे by default hint 'Choose Service' दिसतं.
              Container(
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
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
              const SizedBox(height: 14),

              // ── Order Inspection ───────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _orderInspection,
                          onChanged: (v) => setState(() => _orderInspection = v ?? false),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                        ),
                        const Expanded(
                          child: Text(
                            'Order inspection at just Rs 200/-',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black),
                          ),
                        ),
                      ],
                    ),
                    if (_orderInspection) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFE082)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline, color: Color(0xFFFF8F00), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You will be redirected to PhonePe payment gateway to complete the Rs 200 payment for inspection scheduling.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Schedule Inspection ────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Schedule Your Inspection',
                        style: TextStyle(fontSize: R.sp(context, 14), fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      // Date Picker
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Inspection Date', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                                child: Row(children: [
                                  Expanded(child: Text(
                                    _selectedDate != null ? _formatDate(_selectedDate!) : 'dd/mm/yyyy',
                                    style: TextStyle(fontSize: 13, color: _selectedDate != null ? AppColors.black : AppColors.textMuted),
                                  )),
                                  const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('Starting from tomorrow', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Time Picker
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Inspection Time', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedTime,
                                  hint: const Text('Select Time', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
                                  items: _timeSlots.map((t) => DropdownMenuItem(
                                    value: t['value'],
                                    child: Text(t['label']!, style: const TextStyle(fontSize: 12)),
                                  )).toList(),
                                  onChanged: (v) => setState(() => _selectedTime = v),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('10:00 AM - 5:00 PM', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ✅ NEW: mandatory Terms & Conditions / Privacy Policy checkbox
              TermsCheckbox(
                value: _agreedToTerms,
                onChanged: (v) => setState(() => _agreedToTerms = v),
              ),
              const SizedBox(height: 10),

              // ── Submit Button ──────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitEnquiry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                    // ✅ FIX: Order inspection आता compulsory असल्यामुळे बटण
                    // नेहमी 'Proceed to Payment' दाखवेल.
                    'Proceed to Payment (Rs 200)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({required this.ctrl, required this.hint, this.maxLines = 1, this.keyboardType, this.validator});

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
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.secondary)),
      ),
    );
  }
}