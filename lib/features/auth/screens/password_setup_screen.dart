import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/core/services/api_service.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

/// Called after OTP verified for registration.
/// Handles two cases:
///   1. New user   → full form (name, email, password)
///   2. Existing user (already passenger etc) → upgrade form (no password)
///
/// [extra] = {
///   'phone':            String,
///   'isExistingUser':   bool,   // from verifyOTP response
///   'existingUserName': String? // pre-fill name if upgrading
/// }
class PasswordSetupScreen extends StatefulWidget {
  final String  phone;
  final bool    isExistingUser;    // true = upgrade path, hide password
  final String? existingUserName;  // pre-fill name for existing users

  const PasswordSetupScreen({
    super.key,
    required this.phone,
    this.isExistingUser   = false,
    this.existingUserName,
  });

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final _formKey             = GlobalKey<FormState>();
  final _nameCtrl            = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _hidePassword        = true;
  bool _hideConfirmPassword = true;
  bool _agreeToTerms        = false;
  bool _showTermsError      = false;
  bool _isLoading           = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    // Pre-fill name for upgrade path
    if (widget.isExistingUser && widget.existingUserName != null) {
      _nameCtrl.text = widget.existingUserName!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Password strength helpers ─────────────────────────────────────────────
  bool get _hasMinLength    => _passwordCtrl.text.length >= 8;
  bool get _hasUppercase    => _passwordCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber       => _passwordCtrl.text.contains(RegExp(r'[0-9]'));

  Color _strengthColor() {
    final met = [_hasMinLength, _hasUppercase, _hasNumber]
        .where((b) => b).length;
    if (met == 0) return AppColors.stroke;
    if (met == 1) return AppColors.error;
    if (met == 2) return AppColors.warning;
    return AppColors.success;
  }

  String _strengthLabel() {
    final met = [_hasMinLength, _hasUppercase, _hasNumber]
        .where((b) => b).length;
    if (met == 0) return '';
    if (met == 1) return 'Weak';
    if (met == 2) return 'Fair';
    return 'Strong';
  }

  Future<void> _handleSubmit() async {
    setState(() => _showTermsError = !_agreeToTerms);
    if (!_formKey.currentState!.validate() || !_agreeToTerms) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg  = null;
    });

    try {
      final res = await AuthApi.completeRegistration(
        phone:    widget.phone,
        name:     _nameCtrl.text.trim(),
        // For existing users, password is omitted — backend uses their current password
        password: widget.isExistingUser ? null : _passwordCtrl.text.trim(),
        email:    _emailCtrl.text.trim(),
      );

      if (!mounted) return;
      final ok = (res['status'] as bool?) ?? (res['success'] as bool?) ?? false;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isExistingUser
                  ? 'Agent role added! Submit KYC to activate.'
                  : 'Account created! Please log in.',
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
          _errorMsg = res['message'] as String? ?? 'Registration failed. Please try again.';
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
            widget.isExistingUser ? 'Add Agent Role' : 'Create Account',
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
                const SizedBox(height: AppSpacing.lg),

                // ── Header ───────────────────────────────────────────
                Text(
                  widget.isExistingUser
                      ? 'Add Agent Role\nto Your Account'
                      : 'Complete Your\nRegistration',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.isExistingUser
                      ? 'Your existing account was found. Your password stays the same.'
                      : 'Phone verified! Set up your account to get started.',
                  style: AppTextStyles.bodyMed(AppColors.textSecond),
                ),

                // ── Existing user info banner ─────────────────────────
                if (widget.isExistingUser) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      border: Border.all(
                          color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.success, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Existing account found. Your password and booking history are unchanged. Only the agent role will be added.',
                            style: AppTextStyles.bodySmall(AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xxl),

                // ── Form Card ─────────────────────────────────────────
                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Full Name ──────────────────────────────────
                        _FieldLabel('Full Name'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _nameCtrl,
                          // Read-only for existing users — name already set
                          readOnly: widget.isExistingUser,
                          textCapitalization: TextCapitalization.words,
                          style: AppTextStyles.bodyLarge(
                            widget.isExistingUser
                                ? AppColors.textSecond
                                : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Ram Bahadur Thapa',
                            prefixIcon: const Icon(Icons.person_outline_rounded,
                                color: AppColors.textSecond, size: 20),
                            // Lock icon suffix for existing users
                            suffixIcon: widget.isExistingUser
                                ? const Icon(Icons.lock_outline_rounded,
                                    color: AppColors.textSecond, size: 18)
                                : null,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Full name is required';
                            if (v.trim().length < 3) return 'Name must be at least 3 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // ── Email (optional) ───────────────────────────
                        _FieldLabel('Email (Optional)'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTextStyles.bodyLarge(AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'example@email.com',
                            prefixIcon: Icon(Icons.email_outlined,
                                color: AppColors.textSecond, size: 20),
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(v)) {
                                return 'Enter a valid email address';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // ── Password fields — only for NEW users ───────
                        if (!widget.isExistingUser) ...[
                          const SizedBox(height: AppSpacing.lg),

                          // ── Password ─────────────────────────────────
                          _FieldLabel('Password'),
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
                              if (widget.isExistingUser) return null;
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

                          // Password strength indicator
                          if (_passwordCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _PasswordStrengthBar(
                              color: _strengthColor(),
                              label: _strengthLabel(),
                              checks: [_hasMinLength, _hasUppercase, _hasNumber],
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),

                          // ── Confirm Password ──────────────────────────
                          _FieldLabel('Confirm Password'),
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
                              if (widget.isExistingUser) return null;
                              if (v == null || v.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (v != _passwordCtrl.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),

                        // ── Terms checkbox ─────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _agreeToTerms,
                                onChanged: (v) => setState(() {
                                  _agreeToTerms  = v!;
                                  _showTermsError = false;
                                }),
                                activeColor: AppColors.accentLime,
                                checkColor: AppColors.primaryDark,
                                side: const BorderSide(
                                    color: AppColors.textSecond, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Wrap(
                                children: [
                                  Text('I agree to the ',
                                      style: AppTextStyles.bodySmall(
                                          AppColors.textSecond)),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Text('Terms of Service',
                                        style: AppTextStyles.bodySmall(
                                            AppColors.accentLime)),
                                  ),
                                  Text(' and ',
                                      style: AppTextStyles.bodySmall(
                                          AppColors.textSecond)),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Text('Privacy Policy',
                                        style: AppTextStyles.bodySmall(
                                            AppColors.accentLime)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_showTermsError && !_agreeToTerms) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: AppSpacing.xxl),
                            child: Text(
                              'You must agree to continue',
                              style: AppTextStyles.bodySmall(AppColors.error),
                            ),
                          ),
                        ],

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

                        // Submit CTA
                        PrimaryButton(
                          label: widget.isExistingUser ? 'Add Agent Role' : 'Complete Setup',
                          onPressed: _isLoading ? null : _handleSubmit,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Already have account? ─────────────────────────────
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.login),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyMed(AppColors.textSecond),
                        children: [
                          const TextSpan(text: 'Already have an account?  '),
                          TextSpan(
                            text: 'Log in',
                            style: AppTextStyles.labelMed(AppColors.accentLime),
                          ),
                        ],
                      ),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);
  @override
  Widget build(BuildContext context) =>
      Text(label, style: AppTextStyles.labelSm(AppColors.textSecond));
}

class _PasswordStrengthBar extends StatelessWidget {
  final Color color;
  final String label;
  final List<bool> checks;

  const _PasswordStrengthBar({
    required this.color,
    required this.label,
    required this.checks,
  });

  @override
  Widget build(BuildContext context) {
    final met = checks.where((b) => b).length;
    return Column(
      children: [
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i < met ? color : AppColors.stroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Password strength: ',
                  style: AppTextStyles.bodyTiny(AppColors.textSecond)),
              Text(label,
                  style: AppTextStyles.bodyTiny(color)),
            ],
          ),
        ],
      ],
    );
  }
}
