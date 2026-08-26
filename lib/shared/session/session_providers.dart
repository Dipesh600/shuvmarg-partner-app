import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_service.dart';
import '../../core/storage/session_store.dart';
import 'session_controller.dart';
import 'session_state.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — session providers
///
/// The dependency graph for auth, wired by hand (no codegen) so the tree
/// compiles without a build_runner step:
///
///   sessionStoreProvider  ──►  apiServiceProvider  ──►  (features)
///           │                        │
///           └────────────►  sessionControllerProvider  ◄── router guard
///
/// The one edge that looks circular is not: [apiServiceProvider] holds a closure
/// that reaches [sessionControllerProvider] only when a refresh fails, and
/// [SessionController] reaches [apiServiceProvider] only inside its methods.
/// Neither touches the other at construction time, so there is no build cycle —
/// the lazy `ref.read` is what breaks it.
/// ─────────────────────────────────────────────────────────────────────────────

/// The single secure session store. One instance per container; bootstrap reads
/// it once to prime [SessionStore.cached] before the first frame.
final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStore();
});

/// The single network entry point (production_project_rules.md §4.2).
///
/// Its `onSessionExpired` is deferred with `ref.read`: when the refresh
/// interceptor gives up, it moves the session to expired, which the router's
/// `refreshListenable` turns into a redirect to the welcome screen. Reading the
/// notifier lazily (not at build) is what keeps this provider and the controller
/// from depending on each other at construction.
final apiServiceProvider = Provider<ApiService>((ref) {
  final store = ref.watch(sessionStoreProvider);
  final api = ApiService(
    store: store,
    onSessionExpired: () async {
      ref.read(sessionControllerProvider.notifier).markExpired();
    },
  );
  ref.onDispose(api.dispose);
  return api;
});

/// The app-wide session state the router routes on.
final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
