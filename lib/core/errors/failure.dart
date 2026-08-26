import 'package:flutter/foundation.dart';

import 'backend_error_code.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — failure model
///
/// Every non-success outcome crossing the network boundary becomes exactly one
/// of these. Screens pattern-match on the subtype to choose a *shape* of UI
/// (retry button / support card / countdown / re-login) and read the code and
/// payload for the details.
///
/// Why sealed: `switch` over a sealed hierarchy is exhaustive at compile time,
/// so adding a failure kind later forces every screen that handles failures to
/// acknowledge it instead of silently falling into a default branch.
///
/// Replaces the previous `throw Exception('$message')` pattern, which flattened
/// status code, error code and payload into one unparseable string.
/// ─────────────────────────────────────────────────────────────────────────────
@immutable
sealed class Failure {
  const Failure({
    required this.message,
    this.code = BackendErrorCode.unknown,
    this.rawCode,
    this.statusCode,
    this.data = const {},
    this.cause,
  });

  /// Message safe to show the user. The backend writes these for end users
  /// already; screens may override with their own copy where context helps.
  final String message;

  /// Parsed `errorCode`, or [BackendErrorCode.unknown].
  final BackendErrorCode code;

  /// The original `errorCode` string, kept even when unrecognised so logs and
  /// bug reports never lose it.
  final String? rawCode;

  /// HTTP status, when the request reached the server.
  final int? statusCode;

  /// The decoded response body, for fields specific to one error
  /// (`applicationStatus`, `reason`, `contact`, …). Empty when there was none.
  final Map<String, dynamic> data;

  /// Underlying exception, for logging only. Never shown to a user.
  final Object? cause;

  /// Whether offering a plain "Try again" makes sense.
  ///
  /// False for anything the user cannot fix by repeating the request — a
  /// blocked account, a rejected application, an insufficient role.
  bool get isRetryable => false;

  @override
  String toString() {
    final parts = <String>[
      runtimeType.toString(),
      if (statusCode != null) 'HTTP $statusCode',
      if (rawCode != null && rawCode!.isNotEmpty) rawCode!,
      message,
    ];
    return parts.join(' · ');
  }
}

/// The request never got a usable answer: no connectivity, DNS failure, TLS
/// error, connection refused, or a timeout.
///
/// Distinct from [ServerFailure] because the UI differs — an offline banner and
/// automatic retry-on-reconnect, versus "something broke on our side".
final class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    this.isTimeout = false,
    super.cause,
  });

  /// True when the connection was established but exceeded a timeout — worth
  /// distinguishing so the copy can suggest a better signal rather than
  /// implying there is no connection at all.
  final bool isTimeout;

  @override
  bool get isRetryable => true;
}

/// A 5xx, or a 2xx whose body could not be decoded as the expected JSON.
///
/// The malformed-body case belongs here deliberately: the previous client called
/// `json.decode` unguarded, so an HTML error page from a proxy surfaced as a
/// `FormatException` thrown from inside a widget build.
final class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
    super.code,
    super.rawCode,
    super.data,
    super.cause,
  });

  @override
  bool get isRetryable => true;
}

/// A 401 that survived a token refresh, or a session the server has explicitly
/// invalidated. The only recovery is signing in again.
///
/// Reaching this always means the stored session has already been cleared.
final class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.statusCode,
    super.code,
    super.rawCode,
    super.data,
    super.cause,
  });
}

/// The credentials were accepted but the account itself is barred: deleted,
/// banned, suspended, deactivated or not yet activated.
///
/// The backend ships support contact details with these responses, so the UI can
/// give the user somewhere to go instead of a dead end.
final class AccountBlockedFailure extends Failure {
  const AccountBlockedFailure({
    required super.message,
    required super.code,
    super.rawCode,
    super.statusCode,
    super.data,
    this.reason,
    this.blockedAt,
    this.supportEmail,
    this.supportPhone,
  });

  /// Admin-supplied explanation (`reason` / `suspensionReason`), when present.
  final String? reason;

  /// `suspendedAt` / `bannedAt`, when present.
  final DateTime? blockedAt;

  /// From the response's `contact` object.
  final String? supportEmail;
  final String? supportPhone;

  /// True for an invited-but-not-activated account, which *is* self-resolvable
  /// through the activation flow — unlike every other blocked state.
  bool get isActivatable => code == BackendErrorCode.accountNotActivated;
}

/// A 403 that is about authorisation rather than account standing: the role is
/// wrong for this route, or an agent's KYC application is not approved.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    required super.message,
    required super.code,
    super.rawCode,
    super.statusCode,
    super.data,
  });

  /// Present on [BackendErrorCode.applicationNotApproved]: the current
  /// `applicationStatus` (DRAFT / PENDING / MORE_INFO / REJECTED / SUSPENDED).
  ///
  /// The backend includes it precisely so the gate screen does not need a second
  /// round trip to decide where to send the user.
  String? get applicationStatus {
    final value = data['applicationStatus'];
    return value is String && value.isNotEmpty ? value : null;
  }
}

/// A 4xx rejecting the request's contents — a malformed phone number, a wrong
/// OTP, a missing required field.
///
/// Field-level detail is not modelled: the backend has no single verified schema
/// for it. Read [Failure.data] where a specific endpoint's shape is known.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.rawCode,
    super.statusCode,
    super.data,
  });
}

/// A 429, or any cooldown code. The right UI is a disabled control with a
/// countdown, not an error message the user is invited to retry immediately.
final class ThrottledFailure extends Failure {
  const ThrottledFailure({
    required super.message,
    super.code,
    super.rawCode,
    super.statusCode,
    super.data,
    this.retryAfter,
  });

  /// From the `Retry-After` response header when the server sends one.
  ///
  /// Often absent — account lockout puts the wait in the message text instead.
  /// Screens must handle `null` by showing the message rather than a timer.
  final Duration? retryAfter;
}

/// A 404. Usually a stale identifier — a trip that ended, a ticket already
/// cancelled — rather than a bug.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.statusCode,
    super.code,
    super.rawCode,
    super.data,
  });
}

/// The request was cancelled deliberately, typically because the screen that
/// started it was disposed. Never surfaced to the user.
final class CancelledFailure extends Failure {
  const CancelledFailure({super.message = 'Request cancelled.', super.cause});
}

/// Nothing above fits. Carries [Failure.cause] so the real problem is still
/// diagnosable from logs.
final class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.statusCode,
    super.code,
    super.rawCode,
    super.data,
    super.cause,
  });

  @override
  bool get isRetryable => true;
}
