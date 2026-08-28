import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// Styled password input container with visibility toggle.
class ActivationPasswordField extends StatelessWidget {
  const ActivationPasswordField({
    super.key,
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.enabled,
    this.autofocus = false,
    required this.onToggleObscure,
    required this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool enabled;
  final bool autofocus;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral900.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        autofocus: autofocus,
        cursorColor: AppColors.primary,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            color: AppColors.textPlaceholder,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textPlaceholder,
            ),
            onPressed: onToggleObscure,
          ),
        ),
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
      ),
    );
  }
}

/// Single password requirement rule row.
class ActivationPasswordRule extends StatelessWidget {
  const ActivationPasswordRule({
    super.key,
    required this.label,
    required this.met,
  });

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        met ? Icons.check_circle_rounded : Icons.circle_outlined,
        size: 16,
        color: met ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: met ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
      ),
    ],
  );
}
