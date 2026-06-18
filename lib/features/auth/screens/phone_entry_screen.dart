import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/core/services/api_service.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

/// The mode controls which API is called and where we navigate after.
enum PhoneEntryMode {
  /// New user self-registration — sends REGISTRATION OTP
  signup,
  /// Forgot password — sends PASSWORD_RESET OTP
  forgotPassword,
}

class PhoneEntryScreen extends StatefulWidget {
  final PhoneEntryMode mode;
  const PhoneEntryScreen({
    super.key,
    this.mode = PhoneEntryMode.signup,
  });

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _isLoading  = false;
  bool _isValid    = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(() {
      final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
      setState(() {
        _isValid  = digits.length == 10;
        _errorMsg = null;
      });
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isSignup => widget.mode == PhoneEntryMode.signup;

  Future<void> _submit() async {
    if (!_isValid || _isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg  = null;
    });

    try {
      final phone = '+977${_phoneCtrl.text.trim()}';
      Map<String, dynamic> res;

      if (_isSignup) {
        res = await AuthApi.sendPhoneOtp(phone);
      } else {
        res = await AuthApi.requestPasswordReset(phone);
      }

      if (!mounted) return;

      final ok = (res['status'] as bool?) ?? (res['success'] as bool?) ?? false;
      if (ok) {
        context.push(
          AppRoutes.otpVerify,
          extra: {
            'phone':   phone,
            'purpose': _isSignup ? 'REGISTRATION' : 'PASSWORD_RESET',
          },
        );
      } else {
        setState(() {
          _errorMsg = res['message'] as String? ?? 'Something went wrong.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = 'Network error. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isSignup ? 'Create Account' : 'Reset Password',
          style: AppTextStyles.labelLg(AppColors.textPrimary),
        ),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // ── Header ───────────────────────────────────────────
                  Text(
                    _isSignup
                        ? 'Enter your\nphone number'
                        : 'Forgot your\npassword?',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _isSignup
                        ? "We'll send a 6-digit verification code"
                        : "Enter your phone number and we'll send a reset code",
                    style: AppTextStyles.bodyMed(AppColors.textSecond),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  // ── Phone input ──────────────────────────────────────
                  Text('Phone number',
                      style: AppTextStyles.labelSm(AppColors.textSecond)),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      border: Border.all(
                        color: _errorMsg != null
                            ? AppColors.error
                            : _isValid
                                ? AppColors.accentLime
                                : AppColors.stroke,
                        width: (_isValid || _errorMsg != null) ? 1.5 : 1.0,
                      ),
                      boxShadow: _isValid
                          ? [
                              BoxShadow(
                                color: AppColors.accentLime.withOpacity(0.08),
                                blurRadius: 12,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Country code prefix
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md + 4),
                          decoration: BoxDecoration(
                            border: Border(
                                right: BorderSide(color: AppColors.stroke)),
                          ),
                          child: Row(
                            children: [
                              const Text('🇳🇵',
                                  style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text('+977',
                                  style: AppTextStyles.bodyLarge(
                                      AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        // Number input
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            autofocus: true,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: AppTextStyles.bodyLarge(AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: '98XXXXXXXX',
                              hintStyle: AppTextStyles.bodyLarge(
                                  AppColors.textSecond.withOpacity(0.5)),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md + 4),
                            ),
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ),
                        if (_isValid)
                          Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.lg),
                            child: const Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 20),
                          ),
                      ],
                    ),
                  ),

                  // Error message
                  if (_errorMsg != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(_errorMsg!,
                              style: AppTextStyles.bodySmall(AppColors.error)),
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // ── CTA ──────────────────────────────────────────────
                  PrimaryButton(
                    label: _isSignup ? 'Send OTP' : 'Send Reset Code',
                    onPressed: _isValid ? _submit : null,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Terms (signup only) ──────────────────────────────
                  if (_isSignup)
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style:
                              AppTextStyles.bodySmall(AppColors.textSecond),
                          children: [
                            const TextSpan(
                                text: 'By continuing you agree to our\n'),
                            TextSpan(
                              text: 'Terms of Service',
                              style: AppTextStyles.bodySmall(
                                  AppColors.accentLime),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: AppTextStyles.bodySmall(
                                  AppColors.accentLime),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Already have account? (signup only) ──────────────
                  if (_isSignup) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.push(AppRoutes.login),
                        child: RichText(
                          text: TextSpan(
                            style:
                                AppTextStyles.bodyMed(AppColors.textSecond),
                            children: [
                              const TextSpan(text: 'Already an agent?  '),
                              TextSpan(
                                text: 'Log in',
                                style: AppTextStyles.labelMed(
                                    AppColors.accentLime),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
