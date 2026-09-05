import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure.dart';
import '../../core/errors/result.dart';
import '../../core/network/api_paths.dart';
import '../../domain/agent_application_status.dart';
import '../../domain/app_role.dart';
import 'session_providers.dart';
import 'session_response.dart';
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

/// Owns routed session state and all user-driven writes to the session store.
/// [build] is synchronous: bootstrap has already awaited [SessionStore.read], so
/// the cached session (or its absence) is known before the first frame. Making
/// build synchronous means the router never has to reason about an
/// `AsyncLoading` session — the only "loading" is [SessionRestoring], which the
/// splash owns before this provider is ever read.
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

        final parsed = sessionFromResponse(
          body,
          fallbackRole: role,
          refreshToken: store.lastKnownRefreshToken,
        );
        switch (parsed) {
          case Err(:final failure):
            return SignInOutcome.failure(failure);
          case Ok(:final value):
            await store.write(value);
            state = SessionSignedIn(session: value);
            return SignInOutcome.success(value.activeRole);
        }
    }
  }

  Future<Result<AppRole>> completeForcedPassword({
    required String tempToken,
    required String newPassword,
    required AppRole role,
  }) async {
    final api = ref.read(apiServiceProvider);
    final result = await api.post(
      ApiPaths.changeForcedPassword,
      body: {'tempToken': tempToken, 'newPassword': newPassword},
      authenticated: false,
      appSource: role,
    );
    switch (result) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(:final value):
        return _persistAuthenticatedResponse(value, role);
    }
  }

  Future<Result<AppRole>> activateAccount({
    required String phone,
    required String otp,
    required String newPassword,
    required AppRole role,
  }) async {
    final result = await ref
        .read(apiServiceProvider)
        .post(
          ApiPaths.activate,
          body: {'phone': phone, 'otp': otp, 'newPassword': newPassword},
          authenticated: false,
          appSource: role,
        );
    switch (result) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(:final value):
        return _persistAuthenticatedResponse(value, role);
    }
  }

  Future<Result<AppRole>> recoverPassword({
    required String phone,
    required String otp,
    required String newPassword,
    required AppRole role,
  }) async {
    final result = await ref
        .read(apiServiceProvider)
        .post(
          role == AppRole.driver
              ? ApiPaths.driverResetPassword
              : ApiPaths.agentResetPassword,
          body: {'phone': phone, 'otp': otp, 'newPassword': newPassword},
          authenticated: false,
          appSource: role,
        );
    switch (result) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(:final value):
        final session = await _persistAuthenticatedResponse(value, role);
        if (session case Err(:final failure)) {
          return Result.err(
            ServerFailure(
              message:
                  'Your password was accepted, but automatic sign-in did not finish.',
              data: const {'passwordUpdated': true},
              cause: failure,
            ),
          );
        }
        return session;
    }
  }

  Future<Result<AppRole>> _persistAuthenticatedResponse(
    Map<String, dynamic> response,
    AppRole fallbackRole,
  ) async {
    final store = ref.read(sessionStoreProvider);
    final parsed = sessionFromResponse(
      response,
      fallbackRole: fallbackRole,
      refreshToken: store.lastKnownRefreshToken,
    );
    switch (parsed) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(:final value):
        await store.write(value);
        state = SessionSignedIn(session: value);
        return Result.ok(value.activeRole);
    }
  }

  /// Revokes the server session best-effort, then always clears local state.
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
    await api.post(ApiPaths.logout, body: {'refreshToken': ?refreshToken});

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
