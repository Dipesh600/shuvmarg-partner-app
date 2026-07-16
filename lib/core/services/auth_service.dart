import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUTH STATE
// ─────────────────────────────────────────────────────────────────────────────

enum AuthStatus {
  /// App just launched — haven't checked storage yet
  unknown,
  /// No valid token in storage
  unauthenticated,
  /// Has valid token, but no agent record exists → show application flow
  needsApplication,
  /// Has valid token, application submitted, awaiting admin approval
  applicationPending,
  /// Fully approved agent — show main agent shell
  authenticated,
}

class AuthState {
  final AuthStatus status;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnknown       => status == AuthStatus.unknown;

  AuthState copyWith({
    AuthStatus? status,
    String? accessToken,
    String? refreshToken,
    Map<String, dynamic>? user,
    String? errorMessage,
  }) {
    return AuthState(
      status:       status       ?? this.status,
      accessToken:  accessToken  ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user:         user         ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STORAGE KEYS
// ─────────────────────────────────────────────────────────────────────────────

class _Keys {
  static const accessToken  = 'partner_access_token';
  static const refreshToken = 'partner_refresh_token';
  static const userData     = 'partner_user_data';
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTH NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Called from SplashScreen on app start ─────────────────────────────────
  Future<void> checkAuth() async {
    try {
      final token = await _secure.read(key: _Keys.accessToken);
      if (token == null || token.isEmpty) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_Keys.userData);
      Map<String, dynamic>? user;
      if (userJson != null) {
        user = json.decode(userJson) as Map<String, dynamic>;
      }

      final refreshTok = await _secure.read(key: _Keys.refreshToken);

      // Determine agent status from stored user data
      final appStatus = _resolveStatus(user);

      state = AuthState(
        status:       appStatus,
        accessToken:  token,
        refreshToken: refreshTok,
        user:         user,
      );
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  // ── Save tokens + user after successful login ─────────────────────────────
  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    required Map<String, dynamic> user,
  }) async {
    await _secure.write(key: _Keys.accessToken, value: accessToken);
    if (refreshToken != null) {
      await _secure.write(key: _Keys.refreshToken, value: refreshToken);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_Keys.userData, json.encode(user));
    // Also persist individual fields for easy access across the app
    await prefs.setString('userId',  user['_id']?.toString() ?? '');
    await prefs.setString('name',    user['name']?.toString() ?? '');
    await prefs.setString('phone',   user['phone']?.toString() ?? '');
    await prefs.setString('email',   user['email']?.toString() ?? '');
    await prefs.setString('role',    user['role']?.toString() ?? '');
    await prefs.setString('accessToken', accessToken);
    // NOTE: refreshToken is intentionally NOT stored in SharedPreferences (plaintext).
    // It is stored only in FlutterSecureStorage (OS-protected keychain) above.
    // See NEW-FINDING-03 — SharedPreferences is readable on rooted devices.

    final status = _resolveStatus(user);
    state = AuthState(
      status:       status,
      accessToken:  accessToken,
      refreshToken: refreshToken ?? state.refreshToken,
      user:         user,
    );
  }

  // ── Clear everything on logout ────────────────────────────────────────────
  Future<void> logout() async {
    await _secure.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ── Helper: resolve routing status from user object ───────────────────────
  AuthStatus _resolveStatus(Map<String, dynamic>? user) {
    if (user == null) return AuthStatus.needsApplication;
    final roles = (user['roles'] as List<dynamic>?)?.cast<String>() ?? [];
    final hasAgentRole = roles.contains('agent') || user['role'] == 'agent';
    if (!hasAgentRole) return AuthStatus.needsApplication;
    // If they have the agent role + isVerified, they're approved
    final isVerified = user['isVerified'] as bool? ?? false;
    return isVerified ? AuthStatus.authenticated : AuthStatus.applicationPending;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Convenience: quick access to the current access token string
final accessTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).accessToken;
});
