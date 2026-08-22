import 'package:flutter/foundation.dart';

import '../../domain/agent_application_status.dart';
import '../../domain/session.dart';

/// Why the user is signed out — drives the copy on the welcome screen.
enum SignedOutReason {
  /// The user tapped "Sign out", or the app has never been signed in.
  signedOut,

  /// The session could not be renewed (refresh rejected / token gone). The
  /// welcome screen says "Your session expired, please sign in again" rather
  /// than showing a blank entry point.
  expired,
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — top-level session state
///
/// This is the single fact the router's guard reads to decide where any request
/// is allowed to go. It is deliberately a small sealed set, not a bag of
/// booleans: "restoring", "signed out" and "signed in" are mutually exclusive
/// and the guard `switch`es over them exhaustively, so a new state cannot be
/// added without every routing decision being revisited.
///
/// [SessionRestoring] exists so the splash screen can hold the very first frame
/// while [read] runs, instead of flashing the welcome screen and then redirecting
/// an already-signed-in user. After bootstrap the state is only ever
/// [SessionSignedIn] or [SessionSignedOut].
///
/// Equality is defined on every subtype so Riverpod does not notify — and the
/// router does not rebuild or re-run its redirect — when a rebuild produces an
/// equal state.
/// ─────────────────────────────────────────────────────────────────────────────
@immutable
sealed class SessionState {
  const SessionState();

  /// The live session if signed in, else `null`. Lets call sites read the
  /// session without matching when "signed in or nothing" is the whole rule.
  Session? get sessionOrNull =>
      switch (this) { SessionSignedIn(:final session) => session, _ => null };

  /// Whether a user is signed in. Prefer matching on [SessionSignedIn] when the
  /// session itself is needed.
  bool get isSignedIn => this is SessionSignedIn;
}

/// The app is reading persisted credentials. Transient: set before [read] and
/// replaced the moment it returns. The splash screen renders for this state.
final class SessionRestoring extends SessionState {
  const SessionRestoring();

  @override
  bool operator ==(Object other) => other is SessionRestoring;

  @override
  int get hashCode => (SessionRestoring).hashCode;
}

/// No usable session. The router sends the user to the welcome/sign-in subtree.
final class SessionSignedOut extends SessionState {
  const SessionSignedOut([this.reason = SignedOutReason.signedOut]);

  final SignedOutReason reason;

  @override
  bool operator ==(Object other) =>
      other is SessionSignedOut && other.reason == reason;

  @override
  int get hashCode => Object.hash(SessionSignedOut, reason);
}

/// A user is signed in with a fixed [Session.activeRole].
///
/// [applicationStatus] is meaningful only for agents and caches the KYC gate's
/// last-known value so the workspace can decide what to show without a blocking
/// fetch; it stays `null` for conductors and drivers, and until the status has
/// been loaded. It is *not* an authorisation source — the backend re-checks the
/// gate on every approved-only endpoint — it only shapes the UI.
final class SessionSignedIn extends SessionState {
  const SessionSignedIn({required this.session, this.applicationStatus});

  final Session session;
  final AgentApplicationStatus? applicationStatus;

  SessionSignedIn copyWith({AgentApplicationStatus? applicationStatus}) {
    return SessionSignedIn(
      session: session,
      applicationStatus: applicationStatus ?? this.applicationStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SessionSignedIn &&
      other.session == session &&
      other.applicationStatus == applicationStatus;

  @override
  int get hashCode => Object.hash(SessionSignedIn, session, applicationStatus);
}
