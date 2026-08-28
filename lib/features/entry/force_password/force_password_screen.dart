import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/design.dart';
import '../../../core/errors/result.dart';
import '../../../shared/session/session_providers.dart';
import '../../../shared/ui/ui.dart';
import 'force_password_route.dart';

class ForcePasswordScreen extends ConsumerStatefulWidget {
  const ForcePasswordScreen({super.key, required this.args});

  final ForcePasswordArgs? args;

  @override
  ConsumerState<ForcePasswordScreen> createState() =>
      _ForcePasswordScreenState();
}

class _ForcePasswordScreenState extends ConsumerState<ForcePasswordScreen> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final args = widget.args;
    if (args == null || _submitting) return;
    final password = _password.text;
    final validation = _validate(password, _confirmation.text);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref
        .read(sessionControllerProvider.notifier)
        .completeForcedPassword(
          tempToken: args.tempToken,
          newPassword: password,
          role: args.role,
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        break; // The session-aware router opens the agent workspace.
      case Err(:final failure):
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
    }
  }

  String? _validate(String password, String confirmation) {
    if (password.length < 8) return 'Use at least 8 characters.';
    if (!password.contains(RegExp('[A-Z]'))) {
      return 'Add at least one uppercase letter.';
    }
    if (!password.contains(RegExp('[0-9]'))) {
      return 'Add at least one number.';
    }
    if (password != confirmation) return 'The passwords do not match.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.args == null) return const _ExpiredHandoff();
    return Scaffold(
      backgroundColor: AppColors.canvasAuth,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const Center(child: AppLogo(showPartnerBadge: true, iconSize: 32)),
            const SizedBox(height: AppSpacing.xxxl),
            const AppEyebrow('First sign in'),
            const SizedBox(height: AppSpacing.xs),
            Text('Choose your own password', style: AppText.display3),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'The password from your SMS was only for your first login. Replace it before opening your invitations.',
              style: AppText.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Column(
                children: [
                  AppTextField(
                    label: 'New password',
                    hint: 'At least 8 characters',
                    controller: _password,
                    obscureText: _hidePassword,
                    enabled: !_submitting,
                    suffix: _VisibilityButton(
                      hidden: _hidePassword,
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Confirm password',
                    hint: 'Type it again',
                    controller: _confirmation,
                    obscureText: _hideConfirmation,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    suffix: _VisibilityButton(
                      hidden: _hideConfirmation,
                      onPressed: () => setState(
                        () => _hideConfirmation = !_hideConfirmation,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _PasswordRules(),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppText.bodySm.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Save password and continue',
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({required this.hidden, required this.onPressed});

  final bool hidden;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(
      hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      color: AppColors.textMuted,
    ),
  );
}

class _PasswordRules extends StatelessWidget {
  const _PasswordRules();

  @override
  Widget build(BuildContext context) => AppInsetPanel(
    child: Text(
      'Use 8 or more characters with at least one uppercase letter and one number.',
      style: AppText.bodySm,
    ),
  );
}

class _ExpiredHandoff extends StatelessWidget {
  const _ExpiredHandoff();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.canvasAuth,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock_outlined, color: AppColors.primary),
                const SizedBox(height: AppSpacing.md),
                Text('Start your sign-in again', style: AppText.titleLg),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'The secure password setup link is no longer available.',
                  style: AppText.bodySm,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Back to sign in',
                  onPressed: () => context.go(AppRoutes.welcome),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
