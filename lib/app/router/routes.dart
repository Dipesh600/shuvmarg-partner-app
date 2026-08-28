import '../../domain/app_role.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — route paths
///
/// The app is split into a shared entry area (splash, welcome, sign-in, the
/// "wrong app" page) and three persona subtrees that share nothing but the shell
/// they are hosted in. Each persona's routes hang off its own root — `/agent`,
/// `/conductor`, `/driver` — which is what lets the router enforce, in one place,
/// that a signed-in persona can never navigate into another's subtree (see
/// `guards.dart`).
///
/// Paths are string constants rather than an enum so they compose into deep
/// links (`/agent/bookings/42`) without a lookup table.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppRoutes {
  // ── Shared entry ────────────────────────────────────────────────────────────

  /// First frame. Holds while the persisted session is restored, then the guard
  /// redirects to the right place. Never shown for more than a frame after
  /// bootstrap, which has already awaited the session read.
  static const String splash = '/';

  /// Role picker — the fork between the three personas this app serves.
  static const String welcome = '/welcome';

  /// Sign-in. Carries the chosen role as `?role=<wire>`; an absent or
  /// unrecognised role bounces back to [welcome] (see the per-route redirect).
  static const String signIn = '/sign-in';

  /// First-login password replacement reached with an in-memory temporary
  /// token. The token is deliberately never placed in the URL.
  static const String forcePassword = '/set-password';

  /// Shown when a real platform account belongs to a *different* Shuvmarg app
  /// (passenger, bus owner) — an honest dead-end rather than a failed login.
  static const String wrongApp = '/wrong-app';

  // ── Persona roots ─────────────────────────────────────────────────────────
  // One per role. Everything below these is that persona's private subtree.

  static const String agentHome = '/agent';
  static const String conductorHome = '/conductor';
  static const String driverHome = '/driver';

  /// The home route for [role] — where the guard sends a signed-in user who
  /// lands anywhere they should not be.
  static String homeForRole(AppRole role) => switch (role) {
    AppRole.agent => agentHome,
    AppRole.conductor => conductorHome,
    AppRole.driver => driverHome,
  };

  /// The sign-in location for [role], with the role pre-selected.
  static String signInForRole(AppRole role) => '$signIn?role=${role.wire}';
}
