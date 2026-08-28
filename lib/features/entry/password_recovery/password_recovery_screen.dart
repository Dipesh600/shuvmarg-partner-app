import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/design.dart';
import '../../../core/errors/result.dart';
import '../../../domain/app_role.dart';
import '../../../shared/session/session_providers.dart';
import '../activation/activation_otp_step.dart';
import '../activation/activation_password_step.dart';
import 'password_recovery_repository.dart';
import 'password_recovery_route.dart';
import 'recovery_phone_step.dart';

enum _RecoveryStep { phone, otp, password }

class PasswordRecoveryScreen extends ConsumerStatefulWidget {
  const PasswordRecoveryScreen({super.key, required this.args});

  final PasswordRecoveryArgs? args;

  @override
  ConsumerState<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState
    extends ConsumerState<PasswordRecoveryScreen> {
  _RecoveryStep _step = _RecoveryStep.phone;
  String _phone = '';
  String? _otp;
  String? _error;
  bool _busy = false;

  bool get _validArgs => widget.args?.role == AppRole.agent;

  Future<void> _requestCode(String phone) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _phone = phone;
    });
    final result = await ref
        .read(passwordRecoveryRepositoryProvider)
        .requestCode(phone);
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() {
          _busy = false;
          _step = _RecoveryStep.otp;
        });
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  Future<void> _verifyCode(String otp) async {
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _error = 'Enter the complete 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(passwordRecoveryRepositoryProvider)
        .verifyCode(_phone, otp);
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() {
          _otp = otp;
          _busy = false;
          _step = _RecoveryStep.password;
        });
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  Future<void> _resendCode() async {
    final result = await ref
        .read(passwordRecoveryRepositoryProvider)
        .resendCode(_phone);
    if (!mounted) return;
    if (result case Err(:final failure)) {
      setState(() => _error = failure.message);
    } else {
      setState(() => _error = null);
    }
  }

  Future<void> _savePassword(String password) async {
    final otp = _otp;
    if (_busy || otp == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(sessionControllerProvider.notifier)
        .recoverAgentPassword(phone: _phone, otp: otp, newPassword: password);
    if (!mounted) return;
    if (result case Err(:final failure)) {
      setState(() {
        _busy = false;
        _error = failure.message;
        _step = _RecoveryStep.otp;
        _otp = null;
      });
    }
  }

  void _back() {
    switch (_step) {
      case _RecoveryStep.password:
        setState(() {
          _step = _RecoveryStep.otp;
          _error = null;
        });
      case _RecoveryStep.otp:
        setState(() {
          _step = _RecoveryStep.phone;
          _error = null;
        });
      case _RecoveryStep.phone:
        context.go(AppRoutes.signInForRole(AppRole.agent));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_validArgs) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go(AppRoutes.welcome),
      );
      return const Scaffold(body: SizedBox.shrink());
    }
    final initialPhone = _phone.isNotEmpty ? _phone : widget.args!.phone;
    return Scaffold(
      backgroundColor: AppColors.canvasAuth,
      appBar: AppBar(
        backgroundColor: AppColors.canvasAuth,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _busy ? null : _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: AppMotion.base,
          child: switch (_step) {
            _RecoveryStep.phone => RecoveryPhoneStep(
              initialPhone: initialPhone,
              submitting: _busy,
              error: _error,
              onSubmit: _requestCode,
            ),
            _RecoveryStep.otp => ActivationOtpStep(
              phone: _phone,
              sending: _busy,
              sent: true,
              expiresIn: '5 minutes',
              error: _error,
              onContinue: _verifyCode,
              onResend: _resendCode,
            ),
            _RecoveryStep.password => ActivationPasswordStep(
              submitting: _busy,
              error: _error,
              title: 'Choose a new password',
              description:
                  'Your old password will stop working on every device.',
              actionLabel: 'Save password and sign in',
              onSubmit: _savePassword,
            ),
          },
        ),
      ),
    );
  }
}
