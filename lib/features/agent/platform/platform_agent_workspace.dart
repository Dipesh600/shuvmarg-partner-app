import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../domain/agent_identity.dart';
import '../../../domain/session.dart';
import '../../../shared/ui/ui.dart';
import '../../shell/persona_home_scaffold.dart';
import '../assignments/agent_assignments_section.dart';
import '../identity/agent_identity_section.dart';

/// Workspace for a self-registered, platform-managed agent.
/// Operator-owned shortcuts must not be added here; this scope follows the
/// platform verification and settlement rules supplied by the backend.
class PlatformAgentWorkspace extends StatelessWidget {
  const PlatformAgentWorkspace({
    super.key,
    required this.user,
    required this.identity,
    required this.onSignOut,
  });

  final AuthenticatedUser user;
  final AgentIdentity identity;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => PersonaHomeScaffold(
    user: user,
    onSignOut: onSignOut,
    body: [
      const AppSectionHeader(
        eyebrow: 'Platform agent',
        title: 'Your agent business',
        subtitle:
            'Complete platform verification, then manage the operators you sell for.',
      ),
      const SizedBox(height: AppSpacing.md),
      const AgentIdentitySection(),
      const SizedBox(height: AppSpacing.xl),
      AgentAssignmentsSection(kycCleared: identity.kycCleared),
      const SizedBox(height: AppSpacing.xl),
      WorkspaceAccountCard(user: user, roleLabel: 'Platform agent'),
    ],
  );
}
