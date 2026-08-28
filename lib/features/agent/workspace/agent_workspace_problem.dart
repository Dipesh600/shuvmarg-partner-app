import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../domain/session.dart';
import '../../../shared/ui/ui.dart';
import '../../shell/persona_home_scaffold.dart';

class AgentWorkspaceProblem extends StatelessWidget {
  const AgentWorkspaceProblem({
    super.key,
    required this.user,
    required this.message,
    required this.onSignOut,
    this.onRetry,
  });

  final AuthenticatedUser user;
  final String message;
  final VoidCallback onSignOut;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => PersonaHomeScaffold(
    user: user,
    onSignOut: onSignOut,
    body: [
      const AppSectionHeader(
        eyebrow: 'Agent account',
        title: 'Workspace unavailable',
        subtitle:
            'No selling tools are shown until your account type is known.',
      ),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.person_search_rounded,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppText.bodySm),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton.secondary(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
