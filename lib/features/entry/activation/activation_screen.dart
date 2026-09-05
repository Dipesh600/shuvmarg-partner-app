import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/design.dart';
import '../../../core/errors/backend_error_code.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/result.dart';
import '../../../shared/session/session_providers.dart';
import '../../../shared/ui/ui.dart';
import 'activation_otp_step.dart';
import 'activation_password_step.dart';
import 'activation_phone_step.dart';
import 'activation_repository.dart';
import 'activation_route.dart';

enum _ActivationStep { phone, otp, password }

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key, required this.args});

  final ActivationArgs? args;

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  _ActivationStep _step = _ActivationStep.phone;
  bool _sendingOtp = false;
  bool _submitting = false;
  bool _otpSent = false;
  bool _accountAlreadyActive = false;
  String _phone = '';
  String? _pendingOtp;
  String? _expiresIn;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone = widget.args?.phone?.trim() ?? '';
  }

  Future<void> _sendOtp([String? submittedPhone]) async {
    final args = widget.args;
    if (args == null || _sendingOtp) return;
    final phone = submittedPhone?.trim() ?? _phone;
    setState(() {
      _sendingOtp = true;
      _error = null;
      _accountAlreadyActive = false;
      _phone = phone;
    });
    final result = await ref
        .read(activationRepositoryProvider)
        .sendOtp(phone, args.role);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _sendingOtp = false;
          _otpSent = true;
          _expiresIn = value;
          _step = _ActivationStep.otp;
        });
      case Err(:final failure):
        setState(() {
          _sendingOtp = false;
          _error = failure.message;
          _accountAlreadyActive =
              failure.code == BackendErrorCode.accountAlreadyActive;
        });
    }
  }

  void _phoneChanged(String value) {
    setState(() {
      _phone = value.trim();
      _error = null;
      _accountAlreadyActive = false;
    });
  }

  void _continueWithOtp(String otp) {
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _error = 'Enter the complete 6-digit code.');
      return;
    }
    setState(() {
      _pendingOtp = otp;
      _error = null;
      _step = _ActivationStep.password;
    });
  }

  Future<void> _activate(String password) async {
    final args = widget.args;
    final otp = _pendingOtp;
    if (args == null || otp == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref
        .read(sessionControllerProvider.notifier)
        .activateAccount(
          phone: _phone,
          otp: otp,
          newPassword: password,
          role: args.role,
        );
    if (!mounted) return;
    if (result case Err(:final failure)) {
      if (failure is ValidationFailure) {
        setState(() {
          _step = _ActivationStep.otp;
          _pendingOtp = null;
          _submitting = false;
          _error = failure.message;
        });
      } else {
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
      }
    }
  }

  void _goBack() {
    final args = widget.args;
    if (_step == _ActivationStep.password) {
      setState(() {
        _step = _ActivationStep.otp;
        _error = null;
      });
    } else if (_step == _ActivationStep.otp) {
      setState(() {
        _step = _ActivationStep.phone;
        _error = null;
      });
    } else if (args != null) {
      context.go(AppRoutes.signInForRole(args.role));
    }
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
          tooltip: 'Back',
          onPressed: _submitting ? null : _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: AppMotion.base,
          child: switch (_step) {
            _ActivationStep.phone => ActivationPhoneStep(
              key: const ValueKey('phone-step'),
              role: args.role,
              initialPhone: _phone,
              submitting: _sendingOtp,
              error: _error,
              accountAlreadyActive: _accountAlreadyActive,
              onChanged: _phoneChanged,
              onSubmit: _sendOtp,
              onSignIn: () => context.go(AppRoutes.signInForRole(args.role)),
            ),
            _ActivationStep.otp => ActivationOtpStep(
              key: const ValueKey('otp-step'),
              phone: _phone,
              sending: _sendingOtp,
              sent: _otpSent,
              expiresIn: _expiresIn,
              error: _error,
              onContinue: _continueWithOtp,
              onResend: _sendOtp,
            ),
            _ActivationStep.password => ActivationPasswordStep(
              key: const ValueKey('password-step'),
              submitting: _submitting,
              error: _error,
              onSubmit: _activate,
            ),
          },
        ),
      ),
    );
  }
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
