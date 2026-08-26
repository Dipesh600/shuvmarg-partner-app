import 'package:flutter/foundation.dart';

import 'app_role.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — the signed-in user
///
/// The backend's login mapper returns the whole Mongo user document minus the
/// password hash, so responses carry far more than the app needs. This model
/// deliberately picks out only the fields the UI reads. Parsing narrowly means a
/// new backend field can never break the client, and no incidental personal data
/// gets written to device storage.
/// ─────────────────────────────────────────────────────────────────────────────
@immutable
class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.roles = const [],
    this.isVerified = false,
    this.status,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;

  /// Every role the account holds.
  ///
  /// This is the backend's authorisation source of truth. The singular `role`
  /// field on the document is historical — first-registered role, kept for
  /// analytics — and is intentionally not modelled here so no code can mistake
  /// it for permission.
  final List<String> roles;

  final bool isVerified;

  /// `active` / `invited` / `inactive` / `banned`, when the response includes it.
  final String? status;

  /// True when the account holds [role], and so can sign in with that
  /// `X-App-Source`.
  bool hasRole(AppRole role) => roles.contains(role.wire);

  /// Roles this account holds that this app has a workspace for.
  List<AppRole> get availableRoles =>
      AppRole.values.where(hasRole).toList(growable: false);

  /// First name only — the greeting header shows a single word.
  String get shortName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'there';
    final space = trimmed.indexOf(' ');
    return space == -1 ? trimmed : trimmed.substring(0, space);
  }

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      // Login returns Mongo's `_id`; some endpoints normalise it to `id`.
      id: _string(json['_id']) ?? _string(json['id']) ?? '',
      name: _string(json['name']) ?? '',
      phone: _string(json['phone']) ?? '',
      email: _string(json['email']),
      roles: _stringList(json['roles']),
      isVerified: json['isVerified'] == true,
      status: _string(json['status']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    if (email != null) 'email': email,
    'roles': roles,
    'isVerified': isVerified,
    if (status != null) 'status': status,
  };

  AuthenticatedUser copyWith({
    String? name,
    String? phone,
    String? email,
    List<String>? roles,
    bool? isVerified,
    String? status,
  }) {
    return AuthenticatedUser(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AuthenticatedUser &&
      other.id == id &&
      other.name == name &&
      other.phone == phone &&
      other.email == email &&
      other.isVerified == isVerified &&
      other.status == status &&
      listEquals(other.roles, roles);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    phone,
    email,
    isVerified,
    status,
    Object.hashAll(roles),
  );

  @override
  String toString() => 'AuthenticatedUser($id, $name, roles: $roles)';

  static String? _string(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value == null) return null;
    // Mongo ObjectIds occasionally arrive as `{$oid: "..."}`.
    if (value is Map && value[r'$oid'] is String) return value[r'$oid'] as String;
    return null;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// An authenticated session.
///
/// [activeRole] is fixed for the life of the session. The backend bakes it into
/// the access token at login, decided from the `X-App-Source` header, and offers
/// no way to change it afterwards — so a user who holds both `agent` and
/// `conductor` must sign out and back in to swap workspaces. The app must not
/// present an in-session role switcher, because it cannot honour one.
/// ─────────────────────────────────────────────────────────────────────────────
@immutable
class Session {
  const Session({
    required this.accessToken,
    required this.activeRole,
    required this.user,
    this.refreshToken,
  });

  /// Short-lived bearer token — 15 minutes for all three partner roles.
  final String accessToken;

  /// Long-lived rotating token. 30 days for agents, 7 for conductors and
  /// drivers.
  ///
  /// Nullable because the backend returns it only in a `Set-Cookie` header; if a
  /// proxy strips the header we still have a usable 15-minute session and should
  /// say so at expiry rather than fail at launch.
  final String? refreshToken;

  final AppRole activeRole;
  final AuthenticatedUser user;

  /// Whether this session can outlive the access token's 15-minute window.
  bool get canRefresh => refreshToken != null && refreshToken!.isNotEmpty;

  Session copyWith({
    String? accessToken,
    String? refreshToken,
    AppRole? activeRole,
    AuthenticatedUser? user,
  }) {
    return Session(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      activeRole: activeRole ?? this.activeRole,
      user: user ?? this.user,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Session &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken &&
      other.activeRole == activeRole &&
      other.user == user;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, activeRole, user);

  /// Redacts both tokens — this type ends up in logs and error reports.
  @override
  String toString() =>
      'Session(role: ${activeRole.wire}, user: ${user.id}, '
      'accessToken: <redacted>, refreshToken: '
      '${canRefresh ? '<redacted>' : 'none'})';
}
