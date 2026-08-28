import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../domain/app_role.dart';
import '../widgets/role_support_sheet.dart';
import 'recovery_phone_input.dart';

/// First step in password recovery: Verify registered mobile number.
class RecoveryPhoneStep extends StatefulWidget {
  const RecoveryPhoneStep({
    super.key,
    required this.initialPhone,
    required this.submitting,
    required this.error,
    required this.onSubmit,
  });

  final String initialPhone;
  final bool submitting;
  final String? error;
  final ValueChanged<String> onSubmit;

  @override
  State<RecoveryPhoneStep> createState() => _RecoveryPhoneStepState();
}

class _RecoveryPhoneStepState extends State<RecoveryPhoneStep> {
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
    if (!RegExp(r'^9\d{9}$').hasMatch(phone)) {
      setState(() => _localError = 'Enter a valid 10-digit mobile number.');
      return;
    }
    setState(() => _localError = null);
    widget.onSubmit(phone);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final activeError = _localError ?? widget.error;

    return ListView(
      key: const ValueKey('recovery-phone-content'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        bottomInset > 0 ? bottomInset + AppSpacing.md : AppSpacing.xxl,
      ),
      children: [
        const Text(
          'ACCOUNT RECOVERY',
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
          'Reset your password',
          style: TextStyle(
            fontFamily: 'Neue Machina',
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We will text a verification code to the phone on your agent account.',
          style: TextStyle(
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
          hasError: activeError != null,
          onChanged: (_) => setState(() => _localError = null),
          onSubmitted: _submit,
        ),
        if (activeError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.dangerSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeError,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        RecoveryHelpPill(
          onTap: () => RoleSupportSheet.show(context, role: AppRole.agent),
        ),
      ],
    );
  }
}
