import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../domain/agent_identity.dart';
import '../../../domain/session.dart';
import '../../../shared/ui/ui.dart';
import '../../shell/persona_home_scaffold.dart';
import '../assignments/agent_assignments_section.dart';
import '../identity/agent_identity_section.dart';

/// Workspace for an agent created and paid by a bus operator.
/// Platform settlement and platform-agent onboarding must not be added here.
class OperatorAgentWorkspace extends StatelessWidget {
  const OperatorAgentWorkspace({
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
        eyebrow: 'Operator agent',
        title: 'Your ticket counter',
        subtitle:
            'Manage invitations and sell only for operators that give you access.',
      ),
      const SizedBox(height: AppSpacing.md),
      AgentAssignmentsSection(kycCleared: identity.kycCleared),
      const SizedBox(height: AppSpacing.xl),
      const AppSectionHeader(
        eyebrow: 'Your account',
        title: 'Agent identity',
        subtitle: 'Your agent code, phone verification, and counter details.',
      ),
      const SizedBox(height: AppSpacing.md),
      const AgentIdentitySection(),
      const SizedBox(height: AppSpacing.xl),
      WorkspaceAccountCard(user: user, roleLabel: 'Operator agent'),
    ],
  );
}
