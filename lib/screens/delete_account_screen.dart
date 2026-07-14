// lib/screens/delete_account_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/providers/auth_provider.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _passwordCtrl = TextEditingController();
  final _formKey       = GlobalKey<FormState>();
  bool _obscure        = true;
  bool _isSubmitting   = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final d = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _confirmDelete() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Extra confirmation dialog — irreversible-looking action
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Are you sure?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Your account will be scheduled for permanent deletion. '
              'You can cancel this anytime within the grace period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await ref.read(authProvider.notifier).deleteAccount(
        password: _passwordCtrl.text,
      );

      if (!mounted) return;

      if (response != null) {
        // ✅ Success — show what the server confirmed, then go back to profile.
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Deletion Scheduled', style: TextStyle(fontWeight: FontWeight.w700)),
            content: Text(
              response['message']?.toString() ??
                  'Your account is scheduled for deletion on '
                      '${_formatDate(response['deletion_scheduled_at']?.toString())}. '
                      'You can cancel this request before that date.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) context.pop();
      } else {
        final error = ref.read(authProvider).error ?? 'Failed to schedule deletion';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.secondary),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delete My Account & Data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.black),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please read the information below carefully before proceeding.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // ── What will be deleted ─────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('What will be permanently deleted:',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.secondary, fontSize: 13)),
                    SizedBox(height: 8),
                    _Bullet('Your account (name, email, password, phone number)'),
                    _Bullet('Your saved delivery address'),
                    _Bullet('Your wishlist'),
                    _Bullet('Your blog comments and likes'),
                    _Bullet('All login sessions on all devices'),
                    SizedBox(height: 14),
                    Text('What will NOT be deleted:',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.green, fontSize: 13)),
                    SizedBox(height: 8),
                    _Bullet('Your past orders — retained for legal compliance (GST Act, 7 years)'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Grace period note ─────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '7-day grace period: Once you confirm, your account will be scheduled '
                      'for deletion 7 days from today. You can cancel this request anytime '
                      'before that date from your profile page.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.black, height: 1.4),
                ),
              ),

              const SizedBox(height: 20),

              const Text('Enter your current password to confirm',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                decoration: InputDecoration(
                  hintText: 'Your current password',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.secondary)),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _confirmDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Schedule Account Deletion', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.3))),
        ],
      ),
    );
  }
}