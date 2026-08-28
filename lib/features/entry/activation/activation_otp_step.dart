import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../../../core/design/design.dart';
import '../../../shared/ui/ui.dart';
import 'activation_resend_button.dart';

class ActivationOtpStep extends StatefulWidget {
  const ActivationOtpStep({
    super.key,
    required this.phone,
    required this.sending,
    required this.sent,
    required this.expiresIn,
    required this.error,
    required this.onContinue,
    required this.onResend,
  });

  final String phone;
  final bool sending;
  final bool sent;
  final String? expiresIn;
  final String? error;
  final ValueChanged<String> onContinue;
  final Future<void> Function() onResend;

  @override
  State<ActivationOtpStep> createState() => _ActivationOtpStepState();
}

class _ActivationOtpStepState extends State<ActivationOtpStep> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String get _maskedPhone {
    final phone = widget.phone;
    if (phone.length < 4) return '+977 ••••••••••';
    return '+977 ${phone.substring(0, 2)}••••••${phone.substring(phone.length - 2)}';
  }

  PinTheme _pinTheme(double width) => PinTheme(
    width: width,
    height: 56,
    textStyle: AppText.titleLg,
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.borderInput, width: 1.5),
      borderRadius: AppRadius.inputRadius,
    ),
  );

  Future<void> _resend() async {
    await widget.onResend();
    if (mounted) _code.clear();
  }

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('activation-otp-content'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.xl,
      AppSpacing.xxl,
    ),
    children: [
      const _StepMark(icon: Icons.sms_outlined, label: 'Step 1 of 2'),
      const SizedBox(height: AppSpacing.xl),
      Text('Enter the 6-digit code', style: AppText.display2),
      const SizedBox(height: AppSpacing.xs),
      Text('Sent by SMS to $_maskedPhone', style: AppText.bodySm),
      const SizedBox(height: AppSpacing.xl),
      if (widget.sending)
        const AppCard(child: Center(child: CircularProgressIndicator()))
      else if (!widget.sent)
        _SendProblem(message: widget.error, onRetry: widget.onResend)
      else
        AppCard(
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = ((constraints.maxWidth - 40) / 6).clamp(
                    30.0,
                    48.0,
                  );
                  final theme = _pinTheme(width);
                  return Pinput(
                    length: 6,
                    controller: _code,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    separatorBuilder: (_) =>
                        const SizedBox(width: AppSpacing.xs),
                    defaultPinTheme: theme,
                    focusedPinTheme: theme.copyWith(
                      decoration: theme.decoration?.copyWith(
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.focusRing,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    errorPinTheme: theme.copyWith(
                      decoration: theme.decoration?.copyWith(
                        border: Border.all(color: AppColors.danger, width: 1.5),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Code expires in ${widget.expiresIn ?? '5 minutes'}.',
                style: AppText.caption,
              ),
              if (widget.error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.error!,
                  textAlign: TextAlign.center,
                  style: AppText.bodySm.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Continue securely',
                onPressed: () => widget.onContinue(_code.text),
              ),
              const SizedBox(height: AppSpacing.sm),
              ActivationResendButton(onResend: _resend),
            ],
          ),
        ),
      const SizedBox(height: AppSpacing.lg),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Never share this code.',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ),
        ],
      ),
    ],
  );
}

class _StepMark extends StatelessWidget {
  const _StepMark({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.primarySurface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(label, style: AppText.label.copyWith(color: AppColors.primary)),
    ],
  );
}

class _SendProblem extends StatelessWidget {
  const _SendProblem({required this.message, required this.onRetry});

  final String? message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        const Icon(Icons.sms_failed_outlined, color: AppColors.danger),
        const SizedBox(height: AppSpacing.sm),
        Text(message ?? 'We could not send the code.', style: AppText.bodySm),
        const SizedBox(height: AppSpacing.md),
        AppButton.secondary(label: 'Try again', onPressed: onRetry),
      ],
    ),
  );
}
