import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure.dart';
import '../../core/errors/result.dart';
import '../../core/network/api_paths.dart';
import '../../domain/agent_application_status.dart';
import '../../domain/app_role.dart';
import '../../domain/session.dart';
import 'session_providers.dart';
import 'session_state.dart';

/// The result of a sign-in attempt.
///
/// Sealed so the sign-in screen must handle all three outcomes. The key one is
/// [SignInForcePasswordChange]: the backend answers `200` for a forced password
/// change with no session in the body, which the old client mistook for a
/// successful login and then crashed dereferencing the absent token. Making it a
/// distinct outcome forces the caller to branch instead of assuming success.
@immutable
sealed class SignInOutcome {
  const SignInOutcome();

  /// Signed in. [role] is the session's fixed active role, used to route to the
  /// right persona home.
  const factory SignInOutcome.success(AppRole role) = SignInSuccess;

  /// The account must set a new password before it can be used. [tempToken] is
  /// the short-lived token the change-password call needs (may be `null` if the
  /// backend omitted it — the screen then falls back to the OTP reset flow).
  const factory SignInOutcome.forcePasswordChange(String? tempToken) =
      SignInForcePasswordChange;

  /// The attempt failed. [failure] carries user-facing copy and the code the
  /// screen uses to decide whether to offer activation, reset, or a retry.
  const factory SignInOutcome.failure(Failure failure) = SignInFailure;
}

final class SignInSuccess extends SignInOutcome {
  const SignInSuccess(this.role);
  final AppRole role;
}

final class SignInForcePasswordChange extends SignInOutcome {
  const SignInForcePasswordChange(this.tempToken);
  final String? tempToken;
}

final class SignInFailure extends SignInOutcome {
  const SignInFailure(this.failure);
  final Failure failure;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — session controller
///
/// Owns the [SessionState] the whole app routes on. It is the *only* thing that
/// writes the session store as part of a user-driven flow, so the rules about
/// what a valid session looks like live in one place.
///
/// [build] is synchronous: bootstrap has already awaited [SessionStore.read], so
/// the cached session (or its absence) is known before the first frame. Making
/// build synchronous means the router never has to reason about an
/// `AsyncLoading` session — the only "loading" is [SessionRestoring], which the
/// splash owns before this provider is ever read.
/// ─────────────────────────────────────────────────────────────────────────────
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    final cached = ref.watch(sessionStoreProvider).cached;
    return cached != null
        ? SessionSignedIn(session: cached)
        : const SessionSignedOut();
  }

  /// Signs in against `POST /api/login` with [role] as the `X-App-Source`.
  ///
  /// One endpoint serves all three personas; the header decides which role the
  /// issued token carries. The call is unauthenticated (there is no session yet)
  /// but still sends the app-source override so the server resolves the right
  /// role — the reason [ApiService.post] accepts an [appSource] independent of
  /// the session.
  Future<SignInOutcome> signIn({
    required String emailOrPhone,
    required String password,
    required AppRole role,
  }) async {
    final api = ref.read(apiServiceProvider);
    final store = ref.read(sessionStoreProvider);

    final result = await api.post(
      ApiPaths.login,
      body: {'emailOrPhone': emailOrPhone, 'password': password},
      authenticated: false,
      appSource: role,
    );

    switch (result) {
      case Err(:final failure):
        // State stays SignedOut; the screen shows `failure.message` and decides
        // from its code whether to offer activation or a password reset.
        return SignInOutcome.failure(failure);

      case Ok(:final value):
        final body = value;

        // A 200 that is really a "set your password first" hand-off. There is no
        // session in this body; do not sign in.
        if (body['forcePasswordChange'] == true) {
          final tempToken = body['tempToken'];
          return SignInOutcome.forcePasswordChange(
            tempToken is String && tempToken.isNotEmpty ? tempToken : null,
          );
        }

        final accessToken = body['accessToken'];
        if (accessToken is! String || accessToken.isEmpty) {
          return const SignInOutcome.failure(
            ServerFailure(
              message: 'Sign-in succeeded but no session was returned. '
                  'Please try again.',
            ),
          );
        }

        final userJson = body['user'];
        if (userJson is! Map<String, dynamic>) {
          return const SignInOutcome.failure(
            ServerFailure(
              message: 'Sign-in returned an unexpected response. '
                  'Please try again.',
            ),
          );
        }

        // The server derives the active role from the header we sent, so a
        // parseable value should equal [role]; fall back to the requested role
        // if the field is missing or names a role this app does not serve.
        final activeRoleRaw = body['activeRole'];
        final resolvedRole =
            AppRole.tryParse(activeRoleRaw is String ? activeRoleRaw : null) ??
                role;

        final session = Session(
          accessToken: accessToken,
          activeRole: resolvedRole,
          user: AuthenticatedUser.fromJson(userJson),
          // The rotated refresh token arrived as a Set-Cookie during this very
          // request and was captured synchronously by the interceptor; read it
          // back before `write`, which otherwise persists a token-less session.
          refreshToken: store.lastKnownRefreshToken,
        );

        await store.write(session);
        state = SessionSignedIn(session: session);
        return SignInOutcome.success(resolvedRole);
    }
  }

  /// Signs the user out: revokes the refresh token server-side (best effort),
  /// then clears local state regardless of the network outcome.
  ///
  /// The local clear is unconditional on purpose — if the revoke call fails
  /// (offline, server error) the user must still end up signed out locally, not
  /// trapped in a session they asked to leave. The token version bump on the
  /// server will invalidate the outstanding access token once reachable.
  Future<void> signOut() async {
    final api = ref.read(apiServiceProvider);
    final store = ref.read(sessionStoreProvider);

    final refreshToken = store.lastKnownRefreshToken;
    // Best effort; the result is intentionally ignored.
    await api.post(
      ApiPaths.logout,
      body: {'refreshToken': ?refreshToken},
    );

    await store.clear();
    state = const SessionSignedOut(SignedOutReason.signedOut);
  }

  /// Records that the session expired and could not be renewed.
  ///
  /// Invoked by [ApiService]'s `onSessionExpired` after the refresh interceptor
  /// has already cleared the store, so this only moves the state — it does not
  /// touch storage. Distinguished from [signOut] so the welcome screen can say
  /// the session expired rather than implying the user chose to leave.
  void markExpired() {
    if (state is SessionSignedOut) return;
    state = const SessionSignedOut(SignedOutReason.expired);
  }

  /// Caches the agent KYC gate's latest status on the current session.
  ///
  /// No-op unless signed in. This does not grant access — the backend re-checks
  /// the gate on every approved-only endpoint — it only lets the workspace shape
  /// its UI without a blocking fetch on every navigation.
  void applyApplicationStatus(AgentApplicationStatus? status) {
    final current = state;
    if (current is! SessionSignedIn) return;
    if (current.applicationStatus == status) return;
    state = SessionSignedIn(
      session: current.session,
      applicationStatus: status,
    );
  }
}
