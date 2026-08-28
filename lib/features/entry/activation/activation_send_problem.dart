import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../shared/ui/ui.dart';

/// Fallback card displayed when OTP sending fails.
class ActivationSendProblem extends StatelessWidget {
  const ActivationSendProblem({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String? message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        const Icon(Icons.sms_failed_outlined, color: AppColors.danger),
        const SizedBox(height: AppSpacing.sm),
        Text(message ?? 'We could not send the code.', style: AppText.bodySm),
        const SizedBox(height: AppSpacing.md),
        AppButton.secondary(label: 'Try again', onPressed: onRetry),
      ],
    ),
  );
}
