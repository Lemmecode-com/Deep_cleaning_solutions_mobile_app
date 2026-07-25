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
    return Padding(
      // ✅ NEW: bottom spacing so whatever comes after this widget (submit
      // button, next field, etc.) doesn't sit right on top of the text.
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // ✅ FIX: was .start — checkbox
        // and text now align on the same visual line instead of the text
        // floating below the checkbox.
        children: [
          // ✅ FIX: wrapped Checkbox in a SizedBox + set visualDensity/
          // materialTapTargetSize to shrink its default ~48x48 hit-box.
          // This removes the large invisible padding around the checkbox
          // that was pushing everything apart and causing the misalignment.
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8), // ✅ NEW: small consistent gap instead of relying on default Checkbox padding
          Expanded(
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
        ],
      ),
    );
  }
}