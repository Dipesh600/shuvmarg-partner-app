import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../shared/ui/ui.dart';

class ActivationPasswordStep extends StatefulWidget {
  const ActivationPasswordStep({
    super.key,
    required this.submitting,
    required this.error,
    required this.onSubmit,
  });

  final bool submitting;
  final String? error;
  final ValueChanged<String> onSubmit;

  @override
  State<ActivationPasswordStep> createState() => _ActivationPasswordStepState();
}

class _ActivationPasswordStepState extends State<ActivationPasswordStep> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  bool get _hasLength => _password.text.length >= 8;
  bool get _hasUppercase => RegExp('[A-Z]').hasMatch(_password.text);
  bool get _hasNumber => RegExp('[0-9]').hasMatch(_password.text);

  void _submit() {
    String? error;
    if (!_hasLength) {
      error = 'Use at least 8 characters.';
    } else if (!_hasUppercase) {
      error = 'Add at least one uppercase letter.';
    } else if (!_hasNumber) {
      error = 'Add at least one number.';
    } else if (_password.text != _confirmation.text) {
      error = 'The passwords do not match.';
    }
    if (error != null) {
      setState(() => _localError = error);
      return;
    }
    setState(() => _localError = null);
    widget.onSubmit(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final error = _localError ?? widget.error;
    return ListView(
      key: const ValueKey('activation-password-content'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        const _PasswordStepMark(),
        const SizedBox(height: AppSpacing.xl),
        Text('Create your password', style: AppText.display2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Use this password the next time you sign in.',
          style: AppText.bodySm,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Column(
            children: [
              AppTextField(
                label: 'New password',
                hint: 'Enter a secure password',
                controller: _password,
                obscureText: true,
                enabled: !widget.submitting,
                autofocus: true,
                onChanged: (_) => setState(() => _localError = null),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Confirm password',
                hint: 'Enter it again',
                controller: _confirmation,
                obscureText: true,
                enabled: !widget.submitting,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppInsetPanel(
                child: Column(
                  children: [
                    _PasswordRule(
                      label: '8 or more characters',
                      met: _hasLength,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _PasswordRule(
                      label: 'One uppercase letter',
                      met: _hasUppercase,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _PasswordRule(label: 'One number', met: _hasNumber),
                  ],
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: AppText.bodySm.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Activate my account',
                isLoading: widget.submitting,
                onPressed: widget.submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PasswordStepMark extends StatelessWidget {
  const _PasswordStepMark();

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
        child: const Icon(
          Icons.password_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(
        'Step 2 of 2',
        style: AppText.label.copyWith(color: AppColors.primary),
      ),
    ],
  );
}

class _PasswordRule extends StatelessWidget {
  const _PasswordRule({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        met ? Icons.check_circle_rounded : Icons.circle_outlined,
        size: 17,
        color: met ? AppColors.success : AppColors.textMuted,
      ),
      const SizedBox(width: AppSpacing.xs),
      Expanded(child: Text(label, style: AppText.bodySm)),
    ],
  );
}
