import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design.dart';
import '../../shared/session/session_providers.dart';
import '../../shared/session/session_state.dart';
import '../../shared/ui/ui.dart';
import '../shell/persona_home_scaffold.dart';

/// The conductor workspace home.
///
/// Root of the conductor persona subtree (`/conductor`). Conductors verify
/// tickets and mark boarding on the trips they are assigned; those tools depend
/// on trip and ticket endpoints and land in later commits. For now this confirms
/// the signed-in account and says plainly what is still being built.
class ConductorHomeScreen extends ConsumerWidget {
  const ConductorHomeScreen({super.key});

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
          eyebrow: 'Conductor workspace',
          title: "You're signed in",
        ),
        const SizedBox(height: AppSpacing.md),
        WorkspaceAccountCard(user: user, roleLabel: 'Conductor'),
        const SizedBox(height: AppSpacing.md),
        const WorkspaceNoteCard(
          message: 'Ticket checking and the trip manifest are being set up '
              'for your account. They will appear here as they go live.',
        ),
      ],
    );
  }
}
