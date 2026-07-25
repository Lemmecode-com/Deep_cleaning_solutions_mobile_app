// lib/widgets/terms_checkbox.dart
//
// ✅ Reusable mandatory Terms & Conditions + Privacy Policy checkbox.
// Use this in: register_screen.dart, enquiry_form_screen.dart, checkout_screen.dart
//
// Usage:
//   bool _agreedToTerms = false;   // add this as a state variable
//
//   TermsCheckbox(
//     value: _agreedToTerms,
//     onChanged: (v) => setState(() => _agreedToTerms = v),
//   ),
//
// Before submitting / placing order, ALWAYS check:
//   if (!_agreedToTerms) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Please agree to Terms & Conditions and Privacy Policy'),
//         backgroundColor: AppColors.secondary,
//       ),
//     );
//     return;
//   }

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dcs_app/utils/app_colors.dart';

class TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GestureDetector(
              // ✅ Tapping the text (not just the tiny links) also toggles
              // the checkbox — bigger, easier tap target for mobile users.
              onTap: () => onChanged(!value),
              behavior: HitTestBehavior.opaque,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.push('/terms-conditions'),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.push('/privacy-policy'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}