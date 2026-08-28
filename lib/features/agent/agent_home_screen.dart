import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/session/session_providers.dart';
import '../../shared/session/session_state.dart';
import '../../shared/state/view_state.dart';
import '../shell/persona_home_scaffold.dart';
import 'identity/agent_identity_controller.dart';
import 'operator/operator_agent_workspace.dart';
import 'platform/platform_agent_workspace.dart';
import 'workspace/agent_workspace_kind.dart';
import 'workspace/agent_workspace_problem.dart';

/// Resolves the authenticated agent into exactly one scope-specific workspace.
/// Missing or unknown scope fails closed instead of borrowing another agent
/// type's navigation, rules, or promises.
class AgentHomeScreen extends ConsumerWidget {
  const AgentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionControllerProvider);
    if (sessionState is! SessionSignedIn) return const WorkspaceLoader();

    final identityState = ref.watch(agentIdentityControllerProvider);
    final identityView = identityState.dataOrNull;
    Future<void> signOut() =>
        ref.read(sessionControllerProvider.notifier).signOut();
    Future<void> retry() =>
        ref.read(agentIdentityControllerProvider.notifier).load();
    if (identityView != null) {
      return switch (workspaceKindForScope(identityView.identity.scope)) {
        AgentWorkspaceKind.operatorOwned => OperatorAgentWorkspace(
          user: sessionState.session.user,
          identity: identityView.identity,
          onSignOut: signOut,
        ),
        AgentWorkspaceKind.platform => PlatformAgentWorkspace(
          user: sessionState.session.user,
          identity: identityView.identity,
          onSignOut: signOut,
        ),
        AgentWorkspaceKind.unsupported => AgentWorkspaceProblem(
          user: sessionState.session.user,
          message:
              'We could not identify which agent workspace belongs to this account.',
          onRetry: retry,
          onSignOut: signOut,
        ),
      };
    }

    return switch (identityState) {
      ViewInitial() ||
      ViewLoadingFirst() ||
      ViewSubmitting() => const WorkspaceLoader(),
      ViewEmpty(:final message) => AgentWorkspaceProblem(
        user: sessionState.session.user,
        message: message ?? 'Your agent profile could not be found.',
        onRetry: retry,
        onSignOut: signOut,
      ),
      ViewErrorRetryable(:final failure) ||
      ViewOffline(:final failure) ||
      ViewSubmitFieldErrors(:final failure) => AgentWorkspaceProblem(
        user: sessionState.session.user,
        message: failure.message,
        onRetry: retry,
        onSignOut: signOut,
      ),
      ViewErrorForbidden(:final failure) => AgentWorkspaceProblem(
        user: sessionState.session.user,
        message: failure.message,
        onSignOut: signOut,
      ),
      ViewErrorAuth() => const WorkspaceLoader(),
      ViewData() || ViewLoadingRefresh() => const WorkspaceLoader(),
    };
  }
}
