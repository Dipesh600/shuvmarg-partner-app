import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design.dart';
import '../../shared/session/session_providers.dart';
import '../../shared/session/session_state.dart';
import '../../shared/ui/ui.dart';
import '../shell/persona_home_scaffold.dart';
import 'assignments/agent_assignments_section.dart';
import 'identity/agent_identity_controller.dart';
import 'identity/agent_identity_section.dart';

/// The agent workspace home.
///
/// This is the root of the agent persona subtree (`/agent`). Everything an agent
/// can do hangs below it and is unreachable to the other personas — the router
/// guard enforces that.
///
/// It keeps identity and operator access separate: KYC clears the person, while
/// an ACTIVE assignment grants access to one operator's inventory. Both must be
/// true before the UI says the agent is ready to sell.
class AgentHomeScreen extends ConsumerWidget {
  const AgentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (session is! SessionSignedIn) {
      // Defensive: the guard keeps a signed-out user out of this subtree.
      return const WorkspaceLoader();
    }

    final user = session.session.user;
    final identity = ref
        .watch(agentIdentityControllerProvider)
        .dataOrNull
        ?.identity;
    return PersonaHomeScaffold(
      user: user,
      onSignOut: () => ref.read(sessionControllerProvider.notifier).signOut(),
      body: [
        const AppSectionHeader(
          eyebrow: 'Agent workspace',
          title: 'Your ticket counter',
          subtitle: 'Accept operator invitations before you start selling.',
        ),
        const SizedBox(height: AppSpacing.md),
        AgentAssignmentsSection(kycCleared: identity?.kycCleared),
        const SizedBox(height: AppSpacing.xl),
        const AgentIdentitySection(),
        const SizedBox(height: AppSpacing.xl),
        WorkspaceAccountCard(user: user, roleLabel: 'Agent'),
      ],
    );
  }
}
