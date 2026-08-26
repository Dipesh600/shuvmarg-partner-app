/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — persona roles
///
/// This app serves three of the platform's five roles. Which one you are decides
/// *everything* after the shared entry screens: your route subtree, your
/// navigation bar, your home screen, your endpoints.
///
/// Wire values must be one of the roles the backend recognises on `X-App-Source`
/// (`APP_SOURCE_ROLES` in `src/modules/auth/login/login.policy.js`):
///
///   passenger, busOwner, agent, conductor, driver
///
/// The server lowercases the header and looks the role up on its lowercased form,
/// so casing on the wire does not matter. The lowercase values below are the
/// canonical spelling for the three roles this app serves; send them as-is.
/// ─────────────────────────────────────────────────────────────────────────────
enum AppRole {
  /// Books seats on behalf of walk-in customers. Two sub-types exist
  /// (bus-owner-managed and platform-operated); both are `agent` on the wire and
  /// are distinguished by the `agentType` field on the profile, not by role.
  agent(wire: 'agent', label: 'Agent'),

  /// Rides the bus: verifies tickets, marks boarding, reads the trip manifest.
  /// Provisioned by a bus owner — never self-signup.
  conductor(wire: 'conductor', label: 'Conductor'),

  /// Drives the bus and supplies GPS position. Provisioned by a bus owner.
  driver(wire: 'driver', label: 'Driver');

  const AppRole({required this.wire, required this.label});

  /// Value sent as the `X-App-Source` request header, and the value the backend
  /// returns as `activeRole` in a login response and inside the access token.
  final String wire;

  /// Human-readable name for UI copy.
  final String label;

  /// Parses a backend `activeRole` / `X-App-Source` value.
  ///
  /// Returns `null` for anything this app does not serve — including the two
  /// legitimate platform roles `passenger` and `busOwner`. A `null` here is not
  /// corrupt data: it means a real user signed in with an account that belongs
  /// to a different Shuvmarg app, and the UI should say so rather than crash or
  /// silently treat them as an agent.
  static AppRole? tryParse(String? value) {
    if (value == null) return null;
    final normalised = value.trim().toLowerCase();
    for (final role in AppRole.values) {
      if (role.wire == normalised) return role;
    }
    return null;
  }

  /// Backend roles that are valid platform-wide but have no workspace in this
  /// app. Used to phrase the "wrong app" message precisely.
  static const Set<String> rolesServedByOtherApps = {'passenger', 'busowner'};

  /// True when [value] is a real platform role served by a *different* app.
  static bool belongsToAnotherApp(String? value) =>
      value != null && rolesServedByOtherApps.contains(value.trim().toLowerCase());
}
