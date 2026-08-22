import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design.dart';
import '../../shared/session/session_providers.dart';
import '../../shared/session/session_state.dart';
import '../../shared/ui/ui.dart';
import '../shell/persona_home_scaffold.dart';

/// The agent workspace home.
///
/// This is the root of the agent persona subtree (`/agent`). Everything an agent
/// can do hangs below it and is unreachable to the other personas — the router
/// guard enforces that. For this commit it confirms the signed-in account and is
/// honest about what is still being built; booking, commission and customer
/// tools land in later commits once their endpoints exist.
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
        const WorkspaceNoteCard(
          message: 'Booking, commission and customer tools are being set up '
              'for your account. They will appear here as they go live.',
        ),
      ],
    );
  }
}
