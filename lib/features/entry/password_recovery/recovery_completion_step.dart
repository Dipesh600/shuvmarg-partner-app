import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../shared/ui/ui.dart';

class RecoveryCompletionStep extends StatelessWidget {
  const RecoveryCompletionStep({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('recovery-completion-content'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.xxl,
      AppSpacing.xl,
      AppSpacing.xxl,
    ),
    children: [
      Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            color: AppColors.primary,
            size: 30,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(
        'Your password was saved',
        textAlign: TextAlign.center,
        style: AppText.display2,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Automatic sign-in did not finish. Use your new password to sign in.',
        textAlign: TextAlign.center,
        style: AppText.bodySm,
      ),
      const SizedBox(height: AppSpacing.xl),
      AppCard(
        child: AppButton(
          label: 'Sign in with new password',
          onPressed: onSignIn,
        ),
      ),
    ],
  );
}
