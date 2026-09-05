import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design.dart';
import '../../shared/session/session_providers.dart';
import '../../shared/session/session_state.dart';
import '../../shared/ui/ui.dart';
import '../shell/persona_home_scaffold.dart';
import 'driver_profile_controller.dart';
import 'driver_profile_section.dart';

/// The driver workspace home.
///
/// Root of the driver persona subtree (`/driver`). Drivers share their live
/// location while a trip is running; that needs location permissions and a trip
/// context, which land in later commits. For now this confirms the signed-in
/// account and says plainly what is still being built.
class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (session is! SessionSignedIn) {
      // Defensive: the guard keeps a signed-out user out of this subtree.
      return const WorkspaceLoader();
    }

    final user = session.session.user;
    final profileState = ref.watch(driverProfileControllerProvider);
    // Do not flash the shared User name while the Driver profile loads. That
    // account name may belong to the same person's passenger or agent persona.
    final greetingName = profileState.dataOrNull?.fullName ?? 'Driver';
    return PersonaHomeScaffold(
      user: user,
      greetingName: greetingName,
      onSignOut: () => ref.read(sessionControllerProvider.notifier).signOut(),
      body: [
        const AppSectionHeader(
          eyebrow: 'Driver workspace',
          title: 'Your Driver profile',
          subtitle: 'Details recorded by your bus operator.',
        ),
        const SizedBox(height: AppSpacing.md),
        const DriverProfileSection(),
        const SizedBox(height: AppSpacing.md),
        const WorkspaceNoteCard(
          message:
              'Live location sharing is being set up for your account. '
              'It will appear here once your trips are connected.',
        ),
      ],
    );
  }
}
