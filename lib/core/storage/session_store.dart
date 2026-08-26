import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/app_role.dart';
import '../../domain/session.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — session storage
///
/// The only component permitted to persist credentials. Tokens live exclusively
/// in [FlutterSecureStorage]: the Keychain on iOS, `EncryptedSharedPreferences`
/// on Android.
///
/// The previous implementation wrote the access token to *both* secure storage
/// and plain `SharedPreferences`, which is a world-readable XML file on a rooted
/// device — the encryption was there but bypassed by the duplicate. It also
/// called `prefs.clear()` on logout, destroying unrelated preferences as a side
/// effect. Neither happens here: nothing sensitive touches `SharedPreferences`,
/// and every delete names its key.
///
/// A short-lived in-memory copy backs [cached] so the request interceptor can
/// attach a bearer token without awaiting a Keychain round trip on every call.
/// ─────────────────────────────────────────────────────────────────────────────
class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // Android: back the store with EncryptedSharedPreferences rather
            // than the legacy plaintext-with-encrypted-values scheme.
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            // iOS: `first_unlock` (not the default `unlocked`) so a token
            // refresh can still read the Keychain when the app is resumed in the
            // background after a reboot.
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  final FlutterSecureStorage _storage;

  // ───────────────────────────────────────────────────────────────────────────
  // Secure-storage keys
  //
  // Names carried over from the previous implementation on purpose: an existing
  // install keeps its session instead of being silently signed out on upgrade.
  // ───────────────────────────────────────────────────────────────────────────
  static const String _kAccessToken = 'partner_access_token';
  static const String _kRefreshToken = 'partner_refresh_token';
  static const String _kUser = 'partner_user_data';
  static const String _kActiveRole = 'partner_active_role';

  Session? _cached;

  /// The most recent refresh token this store has seen, held synchronously.
  ///
  /// [updateRefreshToken] is called fire-and-forget by the response interceptor,
  /// so at login the rotated token arrives in the `Set-Cookie` header *before*
  /// [write] persists the session — but [_cached] is still `null` at that point,
  /// so there is no [Session] to hold it on. This slot captures it synchronously
  /// during the interceptor's `onResponse` pass, so [signIn] can read it back
  /// through [lastKnownRefreshToken] and fold it into the [Session] it writes.
  ///
  /// Without it, the login flow captures the cookie and then immediately
  /// clobbers it: [write] runs with a session whose `refreshToken` is null and
  /// deletes the key, leaving the session non-renewable and signing the user out
  /// at the first token refresh. This is the structural fix for that, not a
  /// retry patch over the symptom.
  String? _lastKnownRefreshToken;

  /// The session as last read or written, without touching the Keychain.
  ///
  /// Valid only after [read] has run once — bootstrap does that before any
  /// request is made. Returns `null` when signed out.
  Session? get cached => _cached;

  /// The freshest refresh token known, whether or not a full [Session] has been
  /// assembled yet.
  ///
  /// Prefers the live session's token; falls back to the last value captured by
  /// [updateRefreshToken] before a session existed — the login case, where the
  /// cookie is lifted from the response before [write] runs. Returns `null` when
  /// nothing has been captured.
  String? get lastKnownRefreshToken =>
      _cached?.refreshToken ?? _lastKnownRefreshToken;

  // ───────────────────────────────────────────────────────────────────────────
  // Read
  // ───────────────────────────────────────────────────────────────────────────

  /// Loads the persisted session, or `null` when there is none.
  ///
  /// A partially-written record — access token present but role or user missing,
  /// which can happen if the process died mid-write — is treated as no session
  /// and erased, so the app never boots into a half-authenticated state.
  Future<Session?> read() async {
    try {
      final accessToken = await _storage.read(key: _kAccessToken);
      final roleWire = await _storage.read(key: _kActiveRole);
      final userJson = await _storage.read(key: _kUser);

      final role = AppRole.tryParse(roleWire);

      if (accessToken == null ||
          accessToken.isEmpty ||
          role == null ||
          userJson == null) {
        if (accessToken != null || roleWire != null || userJson != null) {
          // Something was there but it was not a complete session.
          await clear();
        }
        _cached = null;
        return null;
      }

      final decoded = jsonDecode(userJson);
      if (decoded is! Map<String, dynamic>) {
        await clear();
        _cached = null;
        return null;
      }

      _cached = Session(
        accessToken: accessToken,
        refreshToken: await _storage.read(key: _kRefreshToken),
        activeRole: role,
        user: AuthenticatedUser.fromJson(decoded),
      );
      return _cached;
    } catch (error, stack) {
      // A corrupt or unreadable keystore must not brick the app at launch. Drop
      // the record and let the user sign in again.
      if (kDebugMode) {
        debugPrint('SessionStore.read failed, clearing session: $error\n$stack');
      }
      await clear();
      _cached = null;
      return null;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Write
  // ───────────────────────────────────────────────────────────────────────────

  /// Persists [session], replacing anything stored before.
  Future<void> write(Session session) async {
    _cached = session;
    await _storage.write(key: _kAccessToken, value: session.accessToken);
    await _storage.write(key: _kActiveRole, value: session.activeRole.wire);
    await _storage.write(key: _kUser, value: jsonEncode(session.user.toJson()));

    final refresh = session.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      _lastKnownRefreshToken = refresh;
      await _storage.write(key: _kRefreshToken, value: refresh);
    } else {
      // Do not leave a stale refresh token behind a session that has none.
      _lastKnownRefreshToken = null;
      await _storage.delete(key: _kRefreshToken);
    }
  }

  /// Replaces the access token after a refresh, leaving the rest untouched.
  Future<void> updateAccessToken(String accessToken) async {
    final current = _cached;
    if (current == null) return;
    _cached = current.copyWith(accessToken: accessToken);
    await _storage.write(key: _kAccessToken, value: accessToken);
  }

  /// Stores the rotated refresh token.
  ///
  /// The refresh endpoint deletes the presented token server-side and returns
  /// its replacement only in a `Set-Cookie` header, so failing to capture and
  /// save it here means the *next* refresh is rejected and the user is signed
  /// out early.
  Future<void> updateRefreshToken(String refreshToken) async {
    if (refreshToken.isEmpty) return;
    // Capture synchronously before anything awaits: at login the session does
    // not exist yet, so this slot is the only place the just-issued cookie can
    // live until `signIn` folds it into the Session it writes.
    _lastKnownRefreshToken = refreshToken;
    final current = _cached;
    if (current != null) {
      _cached = current.copyWith(refreshToken: refreshToken);
    }
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Clear
  // ───────────────────────────────────────────────────────────────────────────

  /// Erases the stored session.
  ///
  /// Deletes each key by name. `_storage.deleteAll()` is avoided so unrelated
  /// secure entries added later are not collateral damage.
  Future<void> clear() async {
    _cached = null;
    _lastKnownRefreshToken = null;
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kUser);
    await _storage.delete(key: _kActiveRole);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // One-time cleanup of the previous implementation's plaintext copies
  // ───────────────────────────────────────────────────────────────────────────

  /// Removes the credentials the old build mirrored into `SharedPreferences`.
  ///
  /// Upgrading over an old install would otherwise leave a readable access token
  /// and the user's name, phone and email sitting in plaintext XML forever —
  /// deleting the code that wrote them does not delete what it already wrote.
  ///
  /// Runs once at bootstrap and is a no-op afterwards. Each key is removed
  /// individually; the old build's `prefs.clear()` is exactly the behaviour being
  /// corrected. Safe to delete this method once no old installs remain in the
  /// field.
  Future<void> purgeLegacyPlaintextCredentials() async {
    const legacyKeys = <String>[
      'partner_user_data',
      'accessToken',
      'userId',
      'name',
      'phone',
      'email',
      'role',
    ];

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in legacyKeys) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
        }
      }
    } catch (error) {
      // Best-effort hygiene: never block launch on it.
      if (kDebugMode) {
        debugPrint('SessionStore.purgeLegacyPlaintextCredentials: $error');
      }
    }
  }
}
