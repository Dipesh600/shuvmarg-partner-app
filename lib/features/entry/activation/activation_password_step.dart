import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import 'activation_password_field.dart';

class ActivationPasswordStep extends StatefulWidget {
  const ActivationPasswordStep({
    super.key,
    required this.submitting,
    required this.error,
    required this.onSubmit,
    this.title = 'Create your password',
    this.description = 'Use this password the next time you sign in.',
    this.actionLabel = 'Activate my account',
  });

  final bool submitting;
  final String? error;
  final ValueChanged<String> onSubmit;
  final String title;
  final String description;
  final String actionLabel;

  @override
  State<ActivationPasswordStep> createState() => _ActivationPasswordStepState();
}

class _ActivationPasswordStepState extends State<ActivationPasswordStep> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _localError;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  bool get _hasLength => _password.text.length >= 8;
  bool get _hasUppercase => RegExp('[A-Z]').hasMatch(_password.text);
  bool get _hasNumber => RegExp('[0-9]').hasMatch(_password.text);

  void _submit() {
    String? error;
    if (!_hasLength) {
      error = 'Use at least 8 characters.';
    } else if (!_hasUppercase) {
      error = 'Add at least one uppercase letter.';
    } else if (!_hasNumber) {
      error = 'Add at least one number.';
    } else if (_password.text != _confirmation.text) {
      error = 'The passwords do not match.';
    }
    if (error != null) {
      setState(() => _localError = error);
      return;
    }
    setState(() => _localError = null);
    widget.onSubmit(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final error = _localError ?? widget.error;

    return ListView(
      key: const ValueKey('activation-password-content'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        bottomInset > 0 ? bottomInset + AppSpacing.md : AppSpacing.xxl,
      ),
      children: [
        const Text(
          'NEW CREDENTIALS',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Neue Machina',
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.description,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'New password',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ActivationPasswordField(
          controller: _password,
          hint: 'Enter a secure password',
          obscure: _obscurePass,
          enabled: !widget.submitting,
          autofocus: true,
          onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
          onChanged: (_) => setState(() => _localError = null),
        ),
        const SizedBox(height: 16),
        const Text(
          'Confirm password',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ActivationPasswordField(
          controller: _confirmation,
          hint: 'Enter it again',
          obscure: _obscureConfirm,
          enabled: !widget.submitting,
          onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
          onChanged: (_) => setState(() => _localError = null),
          onSubmitted: _submit,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE9ECEF)),
          ),
          child: Column(
            children: [
              ActivationPasswordRule(label: '8 or more characters', met: _hasLength),
              const SizedBox(height: 8),
              ActivationPasswordRule(label: 'One uppercase letter', met: _hasUppercase),
              const SizedBox(height: 8),
              ActivationPasswordRule(label: 'One number', met: _hasNumber),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 14),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.danger,
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.orange400, AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: widget.submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: widget.submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Text(
                      widget.actionLabel,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
