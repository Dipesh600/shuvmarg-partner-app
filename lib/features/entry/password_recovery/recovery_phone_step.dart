import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/design.dart';
import '../../../shared/ui/ui.dart';

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
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('recovery-phone-content'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.xl,
      AppSpacing.xxl,
    ),
    children: [
      Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Recover agent account',
              style: AppText.label.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      Text('Reset your password', style: AppText.display2),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'We will text a verification code to the phone on your agent account.',
        style: AppText.bodySm,
      ),
      const SizedBox(height: AppSpacing.xl),
      AppCard(
        child: Column(
          children: [
            AppTextField(
              label: 'Mobile number',
              hint: '98XXXXXXXX',
              controller: _phone,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              errorText: _localError ?? widget.error,
              enabled: !widget.submitting,
              autofocus: true,
              onChanged: (_) => setState(() => _localError = null),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Send verification code',
              isLoading: widget.submitting,
              onPressed: widget.submitting ? null : _submit,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'For your privacy, we show the same response even if no matching account exists.',
        textAlign: TextAlign.center,
        style: AppText.caption,
      ),
    ],
  );
}
