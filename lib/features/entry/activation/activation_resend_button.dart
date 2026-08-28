import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../shared/ui/ui.dart';

class ActivationResendButton extends StatefulWidget {
  const ActivationResendButton({super.key, required this.onResend});

  final Future<void> Function() onResend;

  @override
  State<ActivationResendButton> createState() => _ActivationResendButtonState();
}

class _ActivationResendButtonState extends State<ActivationResendButton> {
  Timer? _timer;
  int _seconds = 60;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds -= 1);
      }
    });
  }

  Future<void> _resend() async {
    if (_sending || _seconds > 0) return;
    setState(() => _sending = true);
    await widget.onResend();
    if (!mounted) return;
    setState(() => _sending = false);
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    if (_seconds > 0) {
      return Text('Send another code in ${_seconds}s', style: AppText.caption);
    }
    return AppButton.ghost(
      label: 'Send a new code',
      isLoading: _sending,
      onPressed: _sending ? null : _resend,
    );
  }
}
