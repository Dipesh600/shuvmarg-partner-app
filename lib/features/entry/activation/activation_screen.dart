import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/design.dart';
import '../../../core/errors/result.dart';
import '../../../shared/session/session_providers.dart';
import '../../../shared/ui/ui.dart';
import 'activation_repository.dart';
import 'activation_resend_button.dart';
import 'activation_route.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key, required this.args});

  final ActivationArgs? args;

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _sending = true;
  bool _submitting = false;
  bool _otpSent = false;
  String? _expiresIn;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.args != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
    }
  }

  @override
  void dispose() {
    _otp.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final args = widget.args;
    if (args == null || _sending && _otpSent) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await ref
        .read(activationRepositoryProvider)
        .sendOtp(args.phone, args.role);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _sending = false;
          _otpSent = true;
          _expiresIn = value;
        });
      case Err(:final failure):
        setState(() {
          _sending = false;
          _error = failure.message;
        });
    }
  }

  Future<void> _activate() async {
    final args = widget.args;
    if (args == null || _submitting) return;
    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref
        .read(sessionControllerProvider.notifier)
        .activateAccount(
          phone: args.phone,
          otp: _otp.text,
          newPassword: _password.text,
          role: args.role,
        );
    if (!mounted) return;
    if (result case Err(:final failure)) {
      setState(() {
        _submitting = false;
        _error = failure.message;
      });
    }
  }

  String? _validate() {
    if (_otp.text.length != 6) return 'Enter the 6-digit code from your SMS.';
    if (_password.text.length < 8) return 'Use at least 8 characters.';
    if (!RegExp('[A-Z]').hasMatch(_password.text)) {
      return 'Add at least one uppercase letter.';
    }
    if (!RegExp('[0-9]').hasMatch(_password.text)) {
      return 'Add at least one number.';
    }
    if (_password.text != _confirmation.text) {
      return 'The passwords do not match.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    if (args == null) return const _MissingActivation();
    return Scaffold(
      backgroundColor: AppColors.canvasAuth,
      appBar: AppBar(
        backgroundColor: AppColors.canvasAuth,
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.signInForRole(args.role)),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const AppEyebrow('Secure your account'),
            const SizedBox(height: AppSpacing.xs),
            Text('Verify your phone', style: AppText.display3),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_otpSent ? 'We sent' : 'We will send'} a code to +977 ${args.phone}. Choose your own password to activate this account.',
              style: AppText.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_sending)
              const AppCard(child: Center(child: CircularProgressIndicator()))
            else if (!_otpSent)
              _SendProblem(message: _error, onRetry: _sendOtp)
            else
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      label: 'SMS code',
                      hint: '6-digit code',
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      enabled: !_submitting,
                      helperText: 'Valid for ${_expiresIn ?? '5 minutes'}.',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ActivationResendButton(onResend: _sendOtp),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'New password',
                      hint: 'At least 8 characters',
                      controller: _password,
                      obscureText: true,
                      enabled: !_submitting,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Confirm password',
                      hint: 'Type it again',
                      controller: _confirmation,
                      obscureText: true,
                      enabled: !_submitting,
                      onSubmitted: (_) => _activate(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Use an uppercase letter and a number.',
                      style: AppText.caption,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _error!,
                        style: AppText.bodySm.copyWith(color: AppColors.danger),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Activate and continue',
                      isLoading: _submitting,
                      onPressed: _submitting ? null : _activate,
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

class _SendProblem extends StatelessWidget {
  const _SendProblem({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        Text(message ?? 'The code could not be sent.', style: AppText.bodySm),
        const SizedBox(height: AppSpacing.md),
        AppButton.secondary(label: 'Try sending again', onPressed: onRetry),
      ],
    ),
  );
}

class _MissingActivation extends StatelessWidget {
  const _MissingActivation();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: AppButton(
        label: 'Return to sign in',
        onPressed: () => context.go(AppRoutes.welcome),
      ),
    ),
  );
}
