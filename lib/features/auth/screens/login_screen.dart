import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/core/services/api_service.dart';
import 'package:shuvmarg_partner_app/core/services/auth_service.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _phoneCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();

  bool _hidePassword  = true;
  bool _isLoading     = false;
  String? _errorMsg;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim  = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg  = null;
    });

    try {
      final phone    = '+977${_phoneCtrl.text.trim()}';
      final password = _passwordCtrl.text.trim();

      final res = await AuthApi.login(phone, password);
      final success = res['success'] as bool? ?? false;

      if (!mounted) return;

      if (success) {
        await ref.read(authProvider.notifier).saveSession(
          accessToken:  res['accessToken'] as String,
          refreshToken: res['refreshToken'] as String?,
          user:         res['user'] as Map<String, dynamic>,
        );
        if (!mounted) return;
        final status = ref.read(authProvider).status;
        switch (status) {
          case AuthStatus.authenticated:
            context.go(AppRoutes.agentHome);
          case AuthStatus.needsApplication:
            context.go(AppRoutes.appStep1Personal);
          case AuthStatus.applicationPending:
            context.go(AppRoutes.appStatus);
          default:
            context.go(AppRoutes.agentHome);
        }
      } else {
        // Handle specific error codes
        final errorCode = res['errorCode'] as String? ?? '';
        String msg = res['message'] as String? ?? 'Login failed. Please try again.';
        if (errorCode == 'ACCOUNT_NOT_ACTIVATED') {
          msg = 'Your account is not activated yet. Check your SMS for instructions.';
        }
        setState(() => _errorMsg = msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = 'Network error. Please check your connection.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Logo ─────────────────────────────────────────────
                    _buildLogo(),
                    const SizedBox(height: AppSpacing.xxxl),

                    // ── Glass Card Form ───────────────────────────────────
                    GlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: AppTextStyles.heading1(AppColors.textPrimary),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Log in to your agent account',
                              style: AppTextStyles.bodyMed(AppColors.textSecond),
                            ),
                            const SizedBox(height: AppSpacing.xxl),

                            // Phone field
                            Text('Phone number',
                                style: AppTextStyles.labelSm(AppColors.textSecond)),
                            const SizedBox(height: AppSpacing.xs),
                            _PhoneField(controller: _phoneCtrl),
                            const SizedBox(height: AppSpacing.lg),

                            // Password field
                            Text('Password',
                                style: AppTextStyles.labelSm(AppColors.textSecond)),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _hidePassword,
                              style: AppTextStyles.bodyLarge(AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
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
                                if (v.length < 6) return 'At least 6 characters';
                                return null;
                              },
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),

                            // Forgot Password link
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => context.push(AppRoutes.forgotPassword),
                                child: Text(
                                  'Forgot Password?',
                                  style: AppTextStyles.labelSm(AppColors.accentLime),
                                ),
                              ),
                            ),

                            // Error banner
                            if (_errorMsg != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              _ErrorBanner(message: _errorMsg!),
                            ],

                            const SizedBox(height: AppSpacing.xl),

                            // CTA
                            PrimaryButton(
                              label: 'Log In',
                              onPressed: _isLoading ? null : _handleLogin,
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // ── Sign-up link ─────────────────────────────────────
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyMed(AppColors.textSecond),
                          children: [
                            const TextSpan(text: "Don't have an account?  "),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.push(AppRoutes.phoneEntry),
                                child: Text(
                                  'Apply now',
                                  style: AppTextStyles.labelMed(AppColors.accentLime),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Security note
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_outlined,
                              color: AppColors.secondary, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Your data is safe and secure',
                            style: AppTextStyles.bodySmall(AppColors.textSecond),
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
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Shuv ',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              TextSpan(
                text: 'Marg',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentLime,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Partner Portal',
          style: AppTextStyles.bodyMed(AppColors.textSecond),
        ),
      ],
    );
  }
}

// ── Reusable phone field with +977 prefix ─────────────────────────────────────
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: AppTextStyles.bodyLarge(AppColors.textPrimary),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        hintText: '98XXXXXXXX',
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇳🇵', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Container(width: 1, height: 20, color: AppColors.stroke),
              const SizedBox(width: 8),
              Text('+977',
                  style: AppTextStyles.bodyLarge(AppColors.textPrimary)),
            ],
          ),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Phone number is required';
        if (!RegExp(r'^[9][0-9]{9}$').hasMatch(v)) {
          return 'Enter a valid 10-digit number starting with 9';
        }
        return null;
      },
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySmall(AppColors.error)),
          ),
        ],
      ),
    );
  }
}
