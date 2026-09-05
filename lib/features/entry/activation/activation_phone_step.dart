import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../domain/app_role.dart';
import '../../../shared/ui/ui.dart';
import '../password_recovery/recovery_phone_input.dart';

class ActivationPhoneStep extends StatefulWidget {
  const ActivationPhoneStep({
    super.key,
    required this.role,
    required this.initialPhone,
    required this.submitting,
    required this.error,
    required this.accountAlreadyActive,
    required this.onChanged,
    required this.onSubmit,
    required this.onSignIn,
  });

  final AppRole role;
  final String initialPhone;
  final bool submitting;
  final String? error;
  final bool accountAlreadyActive;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onSignIn;

  @override
  State<ActivationPhoneStep> createState() => _ActivationPhoneStepState();
}

class _ActivationPhoneStepState extends State<ActivationPhoneStep> {
  late final TextEditingController _phone;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _phone.text.trim();
    if (!RegExp(r'^9[78]\d{8}$').hasMatch(phone)) {
      setState(() => _localError = 'Enter a valid 10-digit mobile number.');
      return;
    }
    setState(() => _localError = null);
    widget.onSubmit(phone);
  }

  @override
  Widget build(BuildContext context) {
    final error = _localError ?? widget.error;
    final role = widget.role.label.toLowerCase();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return ListView(
      key: const ValueKey('activation-phone-content'),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        bottomInset > 0 ? bottomInset + AppSpacing.md : AppSpacing.xxl,
      ),
      children: [
        const Text(
          'INVITED ACCOUNT',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Set up your account',
          style: TextStyle(
            fontFamily: 'Neue Machina',
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the mobile number on your $role invitation. We will verify the invitation before sending a code.',
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
          'Mobile number',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        RecoveryPhoneInput(
          controller: _phone,
          enabled: !widget.submitting,
          hasError: error != null,
          onChanged: (value) {
            setState(() => _localError = null);
            widget.onChanged(value);
          },
          onSubmitted: _submit,
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.accountAlreadyActive
                  ? AppColors.primarySurface
                  : AppColors.dangerSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  widget.accountAlreadyActive
                      ? Icons.info_outline_rounded
                      : Icons.error_outline_rounded,
                  size: 18,
                  color: widget.accountAlreadyActive
                      ? AppColors.primary
                      : AppColors.danger,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(error, style: AppText.bodySm)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        AppButton(
          label: 'Check invitation and send code',
          isLoading: widget.submitting,
          onPressed: widget.submitting ? null : _submit,
        ),
        if (widget.accountAlreadyActive) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: 'Go to sign in',
            onPressed: widget.onSignIn,
          ),
        ],
      ],
    );
  }
}
