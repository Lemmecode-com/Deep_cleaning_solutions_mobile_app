// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/app_messenger.dart'; // ✅ NEW: root-level SnackBar, survives navigation
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _saving = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  void _prefillFromState(Map<String, dynamic>? user) {
    if (_prefilled || user == null) return;
    _nameController.text = (user['name'] ?? '').toString();
    _emailController.text = (user['email'] ?? '').toString();
    _phoneController.text = (user['phone'] ?? '').toString();
    _prefilled = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final phoneRegex = RegExp(r'^[0-9+\-() ]+$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      // NOTE: assumes `authProvider.notifier` exposes an `updateProfile`
      // method that calls PUT /auth/profile with { name, email, phone }
      // and returns true/false (or throws) on success/failure. If that
      // method doesn't exist yet in auth_provider.dart, add something like:
      //
      // Future<bool> updateProfile({
      //   required String name,
      //   required String email,
      //   String? phone,
      // }) async {
      //   try {
      //     final res = await _apiClient.put('/auth/profile', data: {
      //       'name': name,
      //       'email': email,
      //       'phone': phone,
      //     });
      //     if (res['status'] == true) {
      //       state = state.copyWith(user: res['data']);
      //       return true;
      //     }
      //     return false;
      //   } catch (e) {
      //     return false;
      //   }
      // }
      final success = await ref.read(authProvider.notifier).updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        // ✅ FIX: लगेच Navigator.pop(context) होत होता, त्यामुळे screen
        // destroy होऊन SnackBar काही phones वर दिसतच नव्हता (race
        // condition). root-level AppMessenger वापरून हे fix केलं.
        AppMessenger.showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update profile. Please try again.'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    _prefillFromState(authState.user);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: R.sp(context, 17),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.purpleLight,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(Icons.person,
                      color: AppColors.primary, size: 46),
                ),
              ),
              const SizedBox(height: 28),

              _FieldLabel('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 20),

              _FieldLabel('Email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),

              _FieldLabel('Phone Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  hint: 'Enter your phone number',
                  icon: Icons.phone_outlined,
                ),
                validator: _validatePhone,
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                      : Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: R.sp(context, 15),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true,
      fillColor: AppColors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.secondary),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: R.sp(context, 13),
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
    );
  }
}