import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/core/services/api_service.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

/// Expects [extra] = { 'phone': String, 'purpose': 'REGISTRATION' | 'PASSWORD_RESET' }
class OtpVerifyScreen extends StatefulWidget {
  final String phone;
  final String purpose; // 'REGISTRATION' | 'PASSWORD_RESET'

  const OtpVerifyScreen({
    super.key,
    required this.phone,
    required this.purpose,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _otpCtrl    = TextEditingController();
  final _focusNode  = FocusNode();

  bool    _isLoading    = false;
  bool    _canResend    = false;
  String? _errorMsg;
  int     _countdown    = 45;
  Timer?  _timer;

  bool get _isRegistration => widget.purpose == 'REGISTRATION';

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _countdown = 45;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify(String otp) async {
    if (otp.length != 6 || _isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg  = null;
    });

    try {
      Map<String, dynamic> res;
      if (_isRegistration) {
        res = await AuthApi.verifyPhoneOtp(widget.phone, otp);
      } else {
        res = await AuthApi.verifyOtpForReset(widget.phone, otp);
      }

      if (!mounted) return;
      final ok = (res['status'] as bool?) ?? (res['success'] as bool?) ?? false;

      if (ok) {
        if (_isRegistration) {
          // Pass exists + userName so password_setup_screen can skip password
          // fields for users who already have an account on the platform.
          final isExisting = (res['exists'] as bool?) ?? false;
          final existingName = res['userName'] as String?;
          context.push(AppRoutes.passwordSetup, extra: {
            'phone':            widget.phone,
            'isExistingUser':   isExisting,
            'existingUserName': existingName,
          });
        } else {
          // → New password form
          context.push(AppRoutes.newPassword, extra: {
            'phone': widget.phone,
            'otp':   otp,
          });
        }
      } else {
        setState(() {
          _errorMsg = res['message'] as String? ?? 'Invalid OTP. Please try again.';
          _otpCtrl.clear();
        });
        _focusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Network error. Check your connection.';
          _otpCtrl.clear();
        });
        _focusNode.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    if (!_canResend || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final res = await AuthApi.resendOtp(widget.phone, widget.purpose);
      if (!mounted) return;
      final ok = (res['status'] as bool?) ?? (res['success'] as bool?) ?? false;
      if (ok) {
        _startCountdown();
        _otpCtrl.clear();
        _focusNode.requestFocus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'New code sent to ${widget.phone}',
                style: AppTextStyles.bodyMed(AppColors.textPrimary),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        setState(() => _errorMsg = res['message'] as String? ?? 'Failed to resend.');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Network error. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _formattedCountdown {
    final m = (_countdown ~/ 60).toString().padLeft(2, '0');
    final s = (_countdown % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // ── Pinput themes ──────────────────────────────────────────────────────
    final defaultTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        border: Border.all(color: AppColors.stroke),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedTheme = defaultTheme.copyDecorationWith(
      border: Border.all(color: AppColors.accentLime, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: AppColors.accentLime.withOpacity(0.15),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
    );

    final errorTheme = defaultTheme.copyDecorationWith(
      border: Border.all(color: AppColors.error, width: 1.5),
    );

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Verify Phone',
            style: AppTextStyles.labelLg(AppColors.textPrimary)),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // ── Glowing phone icon ─────────────────────────────────
                _GlowingOtpIcon(),

                const SizedBox(height: AppSpacing.xxl),

                // ── Header ────────────────────────────────────────────
                Text(
                  _isRegistration ? 'OTP Sent!' : 'Reset Code Sent!',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'We sent a 6-digit code to',
                  style: AppTextStyles.bodyMed(AppColors.textSecond),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.phone,
                  style: AppTextStyles.labelMed(AppColors.accentLime),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // ── OTP Form Card ─────────────────────────────────────
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enter OTP',
                          style: AppTextStyles.heading2(AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Enter the 6-digit code sent to your number',
                        style: AppTextStyles.bodyMed(AppColors.textSecond),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Pinput
                      Center(
                        child: Pinput(
                          controller: _otpCtrl,
                          focusNode: _focusNode,
                          length: 6,
                          autofocus: true,
                          defaultPinTheme: defaultTheme,
                          focusedPinTheme: focusedTheme,
                          errorPinTheme: errorTheme,
                          showCursor: true,
                          cursor: Container(
                            width: 2,
                            height: 24,
                            color: AppColors.accentLime,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => setState(() => _errorMsg = null),
                          onCompleted: _verify,
                        ),
                      ),

                      // Error message
                      if (_errorMsg != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.error, size: 16),
                              const SizedBox(width: 6),
                              Text(_errorMsg!,
                                  style: AppTextStyles.bodySmall(
                                      AppColors.error)),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxl),

                      // Resend countdown
                      Center(
                        child: _canResend
                            ? GestureDetector(
                                onTap: _resend,
                                child: Text(
                                  'Resend code',
                                  style: AppTextStyles.labelMed(
                                      AppColors.accentLime),
                                ),
                              )
                            : RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Resend in  ',
                                      style: AppTextStyles.bodyMed(
                                          AppColors.textSecond),
                                    ),
                                    TextSpan(
                                      text: _formattedCountdown,
                                      style: AppTextStyles.labelMed(
                                          AppColors.accentLime),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Verify button
                      PrimaryButton(
                        label: 'Verify Code',
                        onPressed: _otpCtrl.text.length == 6
                            ? () => _verify(_otpCtrl.text)
                            : null,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Support card ──────────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.accentLime.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.headset_mic_rounded,
                            color: AppColors.accentLime, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need help?',
                              style:
                                  AppTextStyles.labelMed(AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Contact our support team',
                              style:
                                  AppTextStyles.bodySmall(AppColors.textSecond)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glowing animated OTP icon ─────────────────────────────────────────────────
class _GlowingOtpIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: AppColors.accentLime.withOpacity(0.06), width: 1),
      ),
      child: Center(
        child: Container(
          height: 84,
          width: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.accentLime.withOpacity(0.15), width: 1),
          ),
          child: Center(
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withOpacity(0.6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentLime.withOpacity(0.30),
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.smartphone_rounded,
                      color: AppColors.accentLime, size: 32),
                  Positioned(
                    top: 4,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.mark_chat_unread_rounded,
                          color: AppColors.accentLime, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
