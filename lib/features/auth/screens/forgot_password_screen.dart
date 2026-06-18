import 'package:flutter/material.dart';
import 'package:shuvmarg_partner_app/features/auth/screens/phone_entry_screen.dart';

/// Forgot password screen — thin wrapper that reuses PhoneEntryScreen
/// in forgotPassword mode so the user enters their phone to receive
/// a PASSWORD_RESET OTP.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PhoneEntryScreen(mode: PhoneEntryMode.forgotPassword);
  }
}
