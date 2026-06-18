import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/core/services/api_service.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

/// Final step in the forgot-password flow.
/// [extra] = { 'phone': String, 'otp': String }
class NewPasswordScreen extends StatefulWidget {
  final String phone;
  final String otp;

  const NewPasswordScreen({
    super.key,
    required this.phone,
    required this.otp,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey              = GlobalKey<FormState>();
  final _passwordCtrl         = TextEditingController();
  final _confirmPasswordCtrl  = TextEditingController();

  bool _hidePassword        = true;
  bool _hideConfirmPassword = true;
  bool _isLoading           = false;
  String? _errorMsg;

  bool get _hasMinLength => _passwordCtrl.text.length >= 8;
  bool get _hasUppercase => _passwordCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber    => _passwordCtrl.text.contains(RegExp(r'[0-9]'));

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg  = null;
    });

    try {
      final res = await AuthApi.resetPassword(
        phone:       widget.phone,
        otp:         widget.otp,
        newPassword: _passwordCtrl.text.trim(),
      );

      if (!mounted) return;
      final ok = (res['status'] as bool?) ?? (res['success'] as bool?) ?? false;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset! Please log in.',
              style: AppTextStyles.bodyMed(AppColors.textPrimary),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (mounted) context.go(AppRoutes.login);
      } else {
        setState(() {
          _errorMsg = res['message'] as String? ?? 'Failed to reset password.';
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
        title: Text('New Password',
            style: AppTextStyles.labelLg(AppColors.textPrimary)),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // ── Lock icon ────────────────────────────────────────
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryDark.withOpacity(0.6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentLime.withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: AppColors.accentLime, size: 32),
                ),

                const SizedBox(height: AppSpacing.xl),

                Text(
                  'Set New Password',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Create a strong password for your account.',
                  style: AppTextStyles.bodyMed(AppColors.textSecond),
                ),

                const SizedBox(height: AppSpacing.xxl),

                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // New Password
                        Text('New Password',
                            style: AppTextStyles.labelSm(AppColors.textSecond)),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _hidePassword,
                          style: AppTextStyles.bodyLarge(AppColors.textPrimary),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Min 8 chars, uppercase & number',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AppColors.textSecond, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecond,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _hidePassword = !_hidePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 8) return 'At least 8 characters';
                            if (!v.contains(RegExp(r'[A-Z]'))) {
                              return 'Include at least one uppercase letter';
                            }
                            if (!v.contains(RegExp(r'[0-9]'))) {
                              return 'Include at least one number';
                            }
                            return null;
                          },
                        ),

                        // Strength bar
                        if (_passwordCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: List.generate(
                              3,
                              (i) {
                                final met = [
                                  _hasMinLength,
                                  _hasUppercase,
                                  _hasNumber
                                ].where((b) => b).length;
                                final barColor = met == 0
                                    ? AppColors.stroke
                                    : met == 1
                                        ? AppColors.error
                                        : met == 2
                                            ? AppColors.warning
                                            : AppColors.success;
                                return Expanded(
                                  child: Container(
                                    margin:
                                        EdgeInsets.only(right: i < 2 ? 4 : 0),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: i < met ? barColor : AppColors.stroke,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        // Confirm Password
                        Text('Confirm Password',
                            style: AppTextStyles.labelSm(AppColors.textSecond)),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _confirmPasswordCtrl,
                          obscureText: _hideConfirmPassword,
                          style: AppTextStyles.bodyLarge(AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Re-enter your password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AppColors.textSecond, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _hideConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecond,
                                size: 20,
                              ),
                              onPressed: () => setState(() =>
                                  _hideConfirmPassword = !_hideConfirmPassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please confirm your password';
                            if (v != _passwordCtrl.text) return 'Passwords do not match';
                            return null;
                          },
                        ),

                        // Error banner
                        if (_errorMsg != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.input),
                              border: Border.all(
                                  color: AppColors.error.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.error, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_errorMsg!,
                                      style: AppTextStyles.bodySmall(
                                          AppColors.error)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xl),

                        PrimaryButton(
                          label: 'Reset Password',
                          onPressed: _isLoading ? null : _submit,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
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
