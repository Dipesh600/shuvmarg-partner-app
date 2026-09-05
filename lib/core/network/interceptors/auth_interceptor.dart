import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/app_role.dart';
import '../../errors/error_mapper.dart';
import '../api_paths.dart';
import '../../storage/session_store.dart';

/// Keys used to pass per-request instructions through `Options.extra`.
///
/// Using `extra` rather than matching on URL paths keeps the policy at the call
/// site: an endpoint is unauthenticated because the caller says so, not because
/// its path happens to contain "login".
abstract final class AuthExtras {
  /// `true` → do not attach an `Authorization` header, and do not try to refresh
  /// on a 401. Set for sign-in, registration, OTP and password-reset calls.
  static const String skipAuth = 'shuvmarg.skipAuth';

  /// An [AppRole] whose wire value becomes the `X-App-Source` header, overriding
  /// the session's active role. Required at login, where no session exists yet.
  static const String appSource = 'shuvmarg.appSource';

  /// Marks a request that has already been replayed once after a refresh, so a
  /// server that keeps answering 401 cannot start an infinite loop.
  static const String retried = 'shuvmarg.retriedAfterRefresh';
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Attaches identity to every outgoing request, and captures the rotated refresh
/// token from every response.
///
/// `X-App-Source` is read from the session's active role. The previous client
/// hardcoded the literal `'agent'` in two places, which meant a conductor or
/// driver could not sign in at all — the server resolved them to the agent role
/// and rejected it. Anything role-dependent must come from the session.
/// ─────────────────────────────────────────────────────────────────────────────
class AuthHeaderInterceptor extends Interceptor {
  AuthHeaderInterceptor(this._store);

  final SessionStore _store;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final skipAuth = options.extra[AuthExtras.skipAuth] == true;
    final session = _store.cached;

    if (!skipAuth && session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    // An explicit override wins; otherwise the session's role. Neither present
    // means the header is omitted, and the server falls back to the account's
    // historical `role` field — acceptable only for calls that do not depend on
    // role selection.
    final override = options.extra[AuthExtras.appSource];
    final role = override is AppRole ? override : session?.activeRole;
    if (role != null) {
      options.headers['X-App-Source'] = role.wire;
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // Login and refresh return the rotated refresh token only as a cookie. Dio
    // has no cookie jar here, so it must be lifted out of the header explicitly
    // or the session silently becomes non-renewable.
    final rotated = readRefreshCookie(response.headers);
    if (rotated != null) {
      // Fire-and-forget: a response must not wait on a Keychain write.
      _store.updateRefreshToken(rotated);
    }
    handler.next(response);
  }

  /// Extracts a portal refresh token from any `Set-Cookie` header on [headers].
  ///
  /// Returns `null` when absent — a proxy that strips `Set-Cookie` leaves the
  /// 15-minute access token working, and that degradation is preferable to
  /// failing the request.
  static String? readRefreshCookie(Headers headers) {
    // Dio normalises response header names to lower case in `Headers.map`.
    final cookies = headers.map['set-cookie'];
    if (cookies == null) return null;

    for (final raw in cookies) {
      for (final part in raw.split(';')) {
        final segment = part.trim();
        for (final name in _refreshCookieNames) {
          final prefix = '$name=';
          if (!segment.startsWith(prefix)) continue;
          final value = segment.substring(prefix.length).trim();
          // An expiring cookie is sent with an empty value; that is a
          // revocation, not a new token.
          if (value.isEmpty) return null;
          return value;
        }
      }
    }
    return null;
  }

  // The API isolates browser sessions by portal. Keep the legacy generic name
  // because older deployments may still return it during a rolling release.
  static const _refreshCookieNames = <String>[
    'agentRefreshToken',
    'driverRefreshToken',
    'busOwnerRefreshToken',
    'passengerRefreshToken',
    'refreshToken',
  ];
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Turns an expired access token into a transparent refresh-and-replay.
///
/// Access tokens last 15 minutes for all three partner roles, so this runs
/// routinely, not exceptionally. The previous client advertised refresh handling
/// in a comment and implemented none of it: any request made after the 15-minute
/// mark simply failed, which is why the app appeared to log users out at random.
///
/// Extends [QueuedInterceptor] so that when several requests fail at once — the
/// usual case, since a screen fires its calls in parallel — only the first
/// triggers a refresh and the rest wait behind it. Firing N refreshes would be
/// self-defeating: the endpoint rotates and deletes the presented token, so the
/// second concurrent call would invalidate the first one's result.
/// ─────────────────────────────────────────────────────────────────────────────
class TokenRefreshInterceptor extends QueuedInterceptor {
  TokenRefreshInterceptor({
    required SessionStore store,
    required Dio client,
    required Future<void> Function() onSessionExpired,
  }) : _store = store,
       _client = client,
       _onSessionExpired = onSessionExpired;

  final SessionStore _store;

  /// The instrumented client, used to replay the original request so it picks up
  /// the new token through [AuthHeaderInterceptor].
  final Dio _client;

  /// Invoked once the session is definitively unrecoverable. Clears state and
  /// lets the router send the user to sign-in.
  final Future<void> Function() _onSessionExpired;

  /// A bare client for the refresh call itself. Deliberately free of
  /// interceptors: routing the refresh through this interceptor would recurse.
  Dio? _refreshClient;

  Dio get _refresher {
    return _refreshClient ??= Dio(
      BaseOptions(
        baseUrl: _client.options.baseUrl,
        connectTimeout: _client.options.connectTimeout,
        receiveTimeout: _client.options.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_isRecoverable(err)) {
      return handler.next(err);
    }

    final refreshToken = _store.cached?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      // Nothing to refresh with — the cookie was never captured, or the session
      // predates it. Sign out rather than retry forever.
      await _expire();
      return handler.next(err);
    }

    final refreshed = await _refresh(refreshToken);
    if (!refreshed) {
      await _expire();
      return handler.next(err);
    }

    // A multipart body is a single-use stream: its file parts were consumed on
    // the first attempt and cannot be replayed. The token is now valid, so the
    // caller's own retry will succeed — see `ApiService.upload`, which rebuilds
    // the form and re-sends once for exactly this case.
    if (err.requestOptions.data is FormData) {
      return handler.next(err);
    }

    try {
      final replayed = await _client.fetch<dynamic>(
        err.requestOptions..extra[AuthExtras.retried] = true,
      );
      return handler.resolve(replayed);
    } on DioException catch (replayError) {
      return handler.next(replayError);
    }
  }

  /// Whether [err] is a 401 that a refresh could plausibly fix.
  bool _isRecoverable(DioException err) {
    if (err.response?.statusCode != 401) return false;
    if (err.requestOptions.extra[AuthExtras.skipAuth] == true) return false;
    if (err.requestOptions.extra[AuthExtras.retried] == true) return false;
    // Never recurse on the refresh endpoint itself.
    if (err.requestOptions.path.contains(ApiPaths.refresh)) return false;
    return true;
  }

  /// Exchanges [refreshToken] for a new access token. Returns whether it worked.
  Future<bool> _refresh(String refreshToken) async {
    try {
      final response = await _refresher.post<dynamic>(
        ApiPaths.refresh,
        data: {'refreshToken': refreshToken},
      );

      final body = ErrorMapper.readJsonBody(response.data);
      final accessToken = body['accessToken'];
      if (accessToken is! String || accessToken.isEmpty) return false;

      await _store.updateAccessToken(accessToken);

      // The presented token has just been deleted server-side. Its replacement
      // arrives only as a cookie, so missing it here means the *next* refresh
      // fails and the user is signed out early.
      final rotated = AuthHeaderInterceptor.readRefreshCookie(response.headers);
      if (rotated != null) {
        await _store.updateRefreshToken(rotated);
      }
      return true;
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Token refresh rejected: HTTP ${error.response?.statusCode}',
        );
      }
      return false;
    } catch (error) {
      if (kDebugMode) debugPrint('Token refresh failed: $error');
      return false;
    }
  }

  Future<void> _expire() async {
    await _store.clear();
    await _onSessionExpired();
  }
}
