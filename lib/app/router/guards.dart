import '../../domain/app_role.dart';
import '../../shared/session/session_state.dart';
import 'routes.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — the routing guard
///
/// A single pure function decides, for any (session, location) pair, whether the
/// navigation is allowed and where to send it otherwise. Keeping it pure — no
/// `BuildContext`, no `ref`, no side effects — means it is trivially testable and
/// runs identically for a tab tap, a deep link, or a `refreshListenable` bump
/// after the session changes.
///
/// Two rules matter for security:
///
///   1. A signed-out user cannot reach any persona subtree. Every workspace
///      location redirects to [AppRoutes.welcome].
///   2. A signed-in user cannot reach a *different* persona's subtree. An agent
///      who deep-links to `/conductor` is redirected to `/agent`. This is
///      re-evaluated on every navigation, so it holds for deep links and for
///      state changes mid-session, not just at sign-in. It is defence in depth,
///      not the primary control — the backend still authorises every request by
///      the token's role — but it stops one persona's UI from ever rendering for
///      another.
/// ─────────────────────────────────────────────────────────────────────────────

/// Returns the location to redirect to, or `null` to allow [location] as-is.
String? sessionRedirect(SessionState state, String location) {
  // Allow the splash screen to hold for its animated brand presentation.
  // The splash screen itself handles the timed navigation hand-off.
  if (location == AppRoutes.splash) {
    return null;
  }

  final persona = _personaForLocation(location);

  return switch (state) {
    // If a restore is in flight, send to splash.
    SessionRestoring() => AppRoutes.splash,

    // Signed out: only the shared entry pages are reachable. A workspace
    // location redirects to the welcome screen.
    SessionSignedOut() =>
      persona != null
          ? AppRoutes.welcome
          : null,

    // Signed in: the user belongs in their own persona subtree.
    SessionSignedIn(:final session) => _signedInRedirect(
      role: session.activeRole,
      persona: persona,
    ),
  };
}

/// Redirect logic for a signed-in user.
///
///   • On a public/entry page ([persona] is null) → go home. A signed-in user
///     has no reason to see splash, welcome, sign-in or the wrong-app page.
///   • In another persona's subtree ([persona] != [role]) → go home. Role
///     isolation.
///   • In their own subtree → allow.
String? _signedInRedirect({required AppRole role, required AppRole? persona}) {
  final home = AppRoutes.homeForRole(role);
  if (persona == null) return home;
  if (persona != role) return home;
  return null;
}

/// Which persona subtree [location] belongs to, or `null` for the shared entry
/// pages (splash, welcome, sign-in, wrong-app).
///
/// Matches the root exactly or as a path prefix (`/agent`, `/agent/bookings`),
/// but not an unrelated path that merely starts with the same letters
/// (`/agentless` would not match `/agent`).
AppRole? _personaForLocation(String location) {
  for (final (root, role) in _personaRoots) {
    if (location == root || location.startsWith('$root/')) return role;
  }
  return null;
}

const List<(String, AppRole)> _personaRoots = [
  (AppRoutes.agentHome, AppRole.agent),
  (AppRoutes.conductorHome, AppRole.conductor),
  (AppRoutes.driverHome, AppRole.driver),
];
