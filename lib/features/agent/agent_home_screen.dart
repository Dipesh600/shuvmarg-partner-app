import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design.dart';
import '../../shared/session/session_providers.dart';
import '../../shared/session/session_state.dart';
import '../../shared/ui/ui.dart';
import '../shell/persona_home_scaffold.dart';
import 'identity/agent_identity_section.dart';

/// The agent workspace home.
///
/// This is the root of the agent persona subtree (`/agent`). Everything an agent
/// can do hangs below it and is unreachable to the other personas — the router
/// guard enforces that.
///
/// What it shows today is the agent's *identity*: the permanent code they hand to
/// a bus operator, and how far through verification they are. That is the whole
/// of what the platform can honestly offer an agent right now — selling requires
/// an operator assignment, and that model does not exist yet — so the screen says
/// so rather than showing tools that would refuse to work.
///
/// The account card comes from the session and the identity section from
/// `GET /api/agent/me`. Two sources on purpose: if the identity request fails the
/// agent still sees who they are signed in as, and the failure is confined to the
/// card that could not load.
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
    return PersonaHomeScaffold(
      user: user,
      onSignOut: () => ref.read(sessionControllerProvider.notifier).signOut(),
      body: [
        const AppSectionHeader(
          eyebrow: 'Agent workspace',
          title: "You're signed in",
        ),
        const SizedBox(height: AppSpacing.md),
        WorkspaceAccountCard(user: user, roleLabel: 'Agent'),
        const SizedBox(height: AppSpacing.md),
        const AgentIdentitySection(),
        const SizedBox(height: AppSpacing.md),
        const WorkspaceNoteCard(
          message: 'Ticket sales, commission and customer tools are still being '
              'built. They will appear here as they go live.',
        ),
      ],
    );
  }
}
