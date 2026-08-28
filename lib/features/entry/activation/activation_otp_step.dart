import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../../../core/design/design.dart';
import 'activation_resend_button.dart';
import 'activation_send_problem.dart';

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
    this.deliveryLabel = 'Sent by SMS to',
  });

  final String phone;
  final bool sending;
  final bool sent;
  final String? expiresIn;
  final String? error;
  final ValueChanged<String> onContinue;
  final Future<void> Function() onResend;
  final String deliveryLabel;

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
    textStyle: const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      borderRadius: BorderRadius.circular(14),
    ),
  );

  Future<void> _resend() async {
    await widget.onResend();
    if (mounted) _code.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ListView(
      key: const ValueKey('activation-otp-content'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        bottomInset > 0 ? bottomInset + AppSpacing.md : AppSpacing.xxl,
      ),
      children: [
        const Text(
          'SECURITY VERIFICATION',
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
          'Enter the 6-digit code',
          style: TextStyle(
            fontFamily: 'Neue Machina',
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.deliveryLabel} $_maskedPhone',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        if (widget.sending)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (!widget.sent)
          ActivationSendProblem(message: widget.error, onRetry: widget.onResend)
        else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final width = ((constraints.maxWidth - 40) / 6).clamp(34.0, 50.0);
              final theme = _pinTheme(width);
              return Pinput(
                length: 6,
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                separatorBuilder: (_) => const SizedBox(width: 8),
                defaultPinTheme: theme,
                focusedPinTheme: theme.copyWith(
                  decoration: theme.decoration?.copyWith(
                    border: Border.all(color: AppColors.primary, width: 1.6),
                  ),
                ),
                errorPinTheme: theme.copyWith(
                  decoration: theme.decoration?.copyWith(
                    border: Border.all(color: AppColors.danger, width: 1.6),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Code expires in ${widget.expiresIn ?? '5 minutes'}.',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.error!,
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
                onPressed: () => widget.onContinue(_code.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Continue securely',
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
          const SizedBox(height: 14),
          ActivationResendButton(onResend: _resend),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.lock_outline_rounded,
              size: 15,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Never share this code.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
