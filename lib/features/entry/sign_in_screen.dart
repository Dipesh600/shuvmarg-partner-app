import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design/design.dart';
import '../../domain/app_role.dart';
import '../../shared/session/session_controller.dart';
import '../../shared/session/session_providers.dart';
import '../../shared/ui/ui.dart';

/// Sign-in for one persona.
///
/// The role is fixed by the time we get here — it was chosen on the welcome
/// screen and arrives as `?role=<wire>`. It is sent as the login's app-source so
/// the backend issues a token for *this* app, and it decides which persona home
/// the guard routes to on success.
///
/// The screen owns only ephemeral form state (`_submitting`, `_errorText`);
/// the session itself lives in [SessionController]. On success it does nothing
/// navigational — the session state change drives the router redirect, so there
/// is exactly one place that decides where a signed-in user lands.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, required this.roleWire});

  /// The `?role=` query value. Validated here; the route also redirects an
  /// absent/unknown role back to the welcome screen before this builds.
  final String? roleWire;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorText;

  AppRole? get _role => AppRole.tryParse(widget.roleWire);

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit(AppRole role) async {
    FocusScope.of(context).unfocus();

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Enter your email or phone and password.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final outcome = await ref.read(sessionControllerProvider.notifier).signIn(
          emailOrPhone: identifier,
          password: password,
          role: role,
        );

    // Signing in changes the session state, which drives the router redirect
    // and disposes this screen — so guard against a late setState.
    if (!mounted) return;

    switch (outcome) {
      case SignInSuccess():
        // The redirect handles navigation. Keep the button in its loading
        // state until the screen is torn down, so it can't be tapped twice.
        break;
      case SignInForcePasswordChange():
        setState(() {
          _submitting = false;
          _errorText = 'You need to set a new password before signing in. '
              'That step is coming soon — please contact your operator.';
        });
      case SignInFailure(:final failure):
        setState(() {
          _submitting = false;
          _errorText = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    if (role == null) {
      // Defensive: the route guard normally prevents an unknown role reaching
      // this screen. If it does, offer a way back rather than a broken form.
      return _InvalidRoleFallback();
    }

    return Scaffold(
      backgroundColor: AppColors.canvasAuth,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(onTap: () => context.go(AppRoutes.welcome)),
              const SizedBox(height: AppSpacing.xl),
              AppEyebrow('${role.label} sign in'),
              const SizedBox(height: AppSpacing.sm),
              Text('Welcome back', style: AppText.display3),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in to your ${role.label.toLowerCase()} workspace.',
                style: AppText.body,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppTextField(
                label: 'Email or phone',
                hint: 'you@example.com',
                controller: _identifierController,
                enabled: !_submitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofocus: true,
                prefixIcon: Icons.person_outline_rounded,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Password',
                controller: _passwordController,
                focusNode: _passwordFocus,
                enabled: !_submitting,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline_rounded,
                errorText: _errorText,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                onSubmitted: (_) => _submit(role),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Sign in',
                isLoading: _submitting,
                onPressed: _submitting ? null : () => _submit(role),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A circular back affordance matching the entry flow's chrome.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.inputRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Shown only if this screen is reached with a role it cannot parse.
class _InvalidRoleFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasAuth,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Choose a role to continue',
                style: AppText.titleMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Back to role selection',
                onPressed: () => context.go(AppRoutes.welcome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
