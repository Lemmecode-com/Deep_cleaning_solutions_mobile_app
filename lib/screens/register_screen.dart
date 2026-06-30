// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/app_images.dart';
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey                = GlobalKey<FormState>();
  final _nameCtrl               = TextEditingController();
  final _emailCtrl              = TextEditingController();
  final _mobileCtrl             = TextEditingController();
  final _passwordCtrl           = TextEditingController();
  final _confirmPasswordCtrl    = TextEditingController();
  bool _obscurePassword         = true;
  bool _obscureConfirmPassword  = true;
  bool _didNavigateAfterRegister = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ mobile काढला — API doc मध्ये register मध्ये mobile नाही
    final success = await ref.read(authProvider.notifier).register(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      final err = ref.read(authProvider).error ?? 'Registration failed!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!_didNavigateAfterRegister && !authState.isLoading && authState.isLoggedIn) {
      _didNavigateAfterRegister = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: R.wp(context, 55),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF3A1F6E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      AppImages.logo,
                      height: 60,
                      width: 180,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign up to get started',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Full Name
                    const Text(
                      'Full Name',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => v!.isEmpty ? 'Name required' : null,
                      decoration: _inputDecoration(
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    const Text(
                      'Email',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.isEmpty) return 'Email required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                      decoration: _inputDecoration(
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mobile Number — UI ठेवला, API ला पाठवत नाही
                    const Text(
                      'Mobile Number',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _mobileCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v!.isEmpty) return 'Mobile required';
                        if (v.length < 10) return 'Invalid mobile number';
                        return null;
                      },
                      decoration: _inputDecoration(
                        hint: 'Enter your mobile number',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    const Text(
                      'Password',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      validator: (v) {
                        if (v!.isEmpty) return 'Password required';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                      decoration: _inputDecoration(
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        suffix: GestureDetector(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    const Text(
                      'Confirm Password',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirmPassword,
                      validator: (v) {
                        if (v!.isEmpty) return 'Confirm password required';
                        if (v != _passwordCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                      decoration: _inputDecoration(
                        hint: 'Confirm your password',
                        icon: Icons.lock_outline,
                        suffix: GestureDetector(
                          onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          child: Icon(
                            _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Register',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary)),
    );
  }
}