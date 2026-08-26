import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import '../../../domain/agent_identity.dart';
import '../../../shared/session/session_providers.dart';
import '../../../shared/state/view_state.dart';
import 'agent_identity_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — agent identity controller
///
/// Owns the state behind the agent home's identity section. Two requests, loaded
/// in two phases on purpose:
///
///   1. `GET /api/agent/me` — the identity. The card paints as soon as this
///      lands, which is the thing the agent came to see.
///   2. `GET /api/agent/me/code` — the server-composed share sentence. Slower to
///      matter and only needed when the agent taps Share, so it must never hold
///      the card behind a spinner. A failure here downgrades the Share action;
///      it does not fail the screen.
///
/// Load failures become [ViewState] through [ViewState.fromFailure], so an
/// expired session, an offline device and a forbidden account each get their own
/// UI shape instead of one red string.
/// ─────────────────────────────────────────────────────────────────────────────

/// The identity plus whatever the share endpoint has told us so far.
class AgentIdentityView {
  const AgentIdentityView({required this.identity, this.sharePayload});

  final AgentIdentity identity;

  /// `null` while the code request is in flight, and after it fails. The Share
  /// action stays disabled until the server gives us its wording — the app does
  /// not invent a sentence of its own.
  final String? sharePayload;

  AgentIdentityView withSharePayload(String? payload) =>
      AgentIdentityView(identity: identity, sharePayload: payload);

  @override
  bool operator ==(Object other) =>
      other is AgentIdentityView &&
      other.identity == identity &&
      other.sharePayload == sharePayload;

  @override
  int get hashCode => Object.hash(identity, sharePayload);
}

final agentIdentityRepositoryProvider = Provider<AgentIdentityRepository>((ref) {
  return AgentIdentityRepository(ref.watch(apiServiceProvider));
});

/// `autoDispose` on purpose. Verification advances on the *server* — an operator
/// confirms a phone, a reviewer approves an application — so a cached identity
/// goes stale without anything happening in the app. Disposing when the agent
/// leaves the screen means coming back refetches, instead of showing the state
/// from whenever the provider first ran. Both requests are cheap.
final agentIdentityControllerProvider = NotifierProvider.autoDispose<
  AgentIdentityController,
  ViewState<AgentIdentityView>
>(AgentIdentityController.new);

class AgentIdentityController
    extends AutoDisposeNotifier<ViewState<AgentIdentityView>> {
  /// Set by [Ref.onDispose]. A response that arrives after the provider is gone
  /// must be dropped, not written — writing to a disposed notifier throws, and
  /// the agent has already left the screen.
  bool _disposed = false;

  @override
  ViewState<AgentIdentityView> build() {
    ref.onDispose(() => _disposed = true);
    // Kick the first load off the build phase: a Notifier may not write its own
    // state while constructing it.
    Future.microtask(load);
    return const ViewState.loadingFirst();
  }

  /// Loads the identity. Keeps any data already on screen visible while
  /// refetching, so a pull-to-refresh does not blank the card.
  Future<void> load() async {
    final existing = state.dataOrNull;
    _set(
      existing == null
          ? const ViewState.loadingFirst()
          : ViewState.loadingRefresh(existing),
    );

    final result = await ref.read(agentIdentityRepositoryProvider).load();
    if (_disposed) return;

    switch (result) {
      case Ok(:final value):
        // Carry the previous share payload across a refresh so the Share button
        // does not flicker back to disabled while phase 2 re-runs.
        _set(
          ViewState.data(
            AgentIdentityView(
              identity: value,
              sharePayload: existing?.sharePayload,
            ),
          ),
        );
        await _loadSharePayload();
      case Err(:final failure):
        _set(ViewState.fromFailure<AgentIdentityView>(failure));
    }
  }

  /// Phase 2. Deliberately silent on failure: the identity is already on screen
  /// and correct, and the only casualty is the Share action.
  Future<void> _loadSharePayload() async {
    final result = await ref
        .read(agentIdentityRepositoryProvider)
        .loadShareableCode();
    if (_disposed) return;

    final current = state.dataOrNull;
    if (current == null) return;

    switch (result) {
      case Ok(:final value):
        _set(ViewState.data(current.withSharePayload(value.sharePayload)));
      case Err():
        break;
    }
  }

  void _set(ViewState<AgentIdentityView> next) {
    if (_disposed) return;
    state = next;
  }
}
