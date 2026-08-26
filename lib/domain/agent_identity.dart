import 'package:flutter/foundation.dart';

import 'agent_application_status.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — the agent's own identity
///
/// Parsed from `GET /api/agent/me` (`src/modules/agent/identity/`). This is the
/// agent's portable identity on the platform: a permanent code they hand to a
/// bus operator, the kind of outlet they run, and how far through verification
/// they are.
///
/// WHAT THIS IS NOT: permission to sell. An agent code plus cleared KYC still
/// sells nothing — that needs an operator assignment, which the backend does not
/// have yet. Nothing here should ever be read as "can book".
///
/// Parsed narrowly, like `AuthenticatedUser`: only fields a screen renders. Two
/// deliberate omissions —
///   • `name` / `phone` / `photoUrl` — the session already carries these and the
///     account card renders them from there. Parsing them again would give one
///     fact two sources that can disagree.
///   • `assignments` — the endpoint returns `{total: 0, active: 0, invited: 0}`
///     unconditionally today because the assignment model does not exist. The
///     zeros are a placeholder, not a count, and showing "0 assignments" would
///     tell the agent something we do not actually know. Parse it when it means
///     something.
/// ─────────────────────────────────────────────────────────────────────────────

/// Who owns the agent relationship.
enum AgentScope {
  /// Self-registered. Sells any operator's inventory; the platform pays them.
  platform('PLATFORM', 'Platform agent'),

  /// Created by, and paid by, a bus operator. Sells only for operators that
  /// have assigned them. The platform settles nothing with these agents.
  ///
  /// Not named `operator` — that is a Dart keyword.
  operatorOwned('OPERATOR', 'Operator agent');

  const AgentScope(this.wire, this.label);

  /// Exact string the backend uses in `scope`.
  final String wire;

  /// Short human-readable name.
  final String label;

  /// Parses a backend `scope`. Returns `null` for anything unrecognised rather
  /// than guessing a scope — the two scopes have different rules, and defaulting
  /// would silently apply the wrong ones.
  static AgentScope? tryParse(String? value) {
    if (value == null) return null;
    final normalised = value.trim().toUpperCase();
    for (final scope in AgentScope.values) {
      if (scope.wire == normalised) return scope;
    }
    return null;
  }
}

/// What kind of shopfront the agent runs. Presentation only — no rule reads it.
enum AgentOutletType {
  ticketCounter('TICKET_COUNTER', 'Ticket counter'),
  travelAgency('TRAVEL_AGENCY', 'Travel agency'),
  mobileShop('MOBILE_SHOP', 'Mobile shop'),
  hotel('HOTEL', 'Hotel'),
  solo('SOLO', 'Solo agent');

  const AgentOutletType(this.wire, this.label);

  final String wire;
  final String label;

  static AgentOutletType? tryParse(String? value) {
    if (value == null) return null;
    final normalised = value.trim().toUpperCase();
    for (final type in AgentOutletType.values) {
      if (type.wire == normalised) return type;
    }
    return null;
  }
}

@immutable
class AgentIdentity {
  const AgentIdentity({
    required this.agentCode,
    required this.legacyAgentId,
    required this.scope,
    required this.outletType,
    required this.kycStatus,
    required this.kycStatusLabel,
    required this.kycCleared,
    required this.createdByOperator,
    this.district,
    this.municipality,
    this.placeName,
    this.businessName,
    this.shopAddress,
  });

  /// The permanent `SM-AG-…` code the agent shares with a bus operator.
  ///
  /// Nullable because a profile written before the scheme existed may not have
  /// one yet. A screen must render the absence honestly rather than show an
  /// empty box that looks like a code.
  final String? agentCode;

  /// The superseded `SHV-AG-…` identifier, kept only so an agent who wrote the
  /// old one down can still be matched. Never offered as the code to share.
  final String? legacyAgentId;

  /// `null` when the server sent a scope this build does not know.
  final AgentScope? scope;

  final AgentOutletType? outletType;

  /// `null` when the server sent a status this build does not know. The screen
  /// then falls back to [kycStatusLabel], which is server-authored copy and so
  /// stays correct even for a status added after this build shipped.
  final AgentApplicationStatus? kycStatus;

  /// Server-authored sentence describing the status to the agent.
  final String? kycStatusLabel;

  /// The server's answer to "does this agent's own verification permit selling".
  ///
  /// Scope-dependent (VERIFIED_BASIC for an operator agent, APPROVED for a
  /// platform one), which is exactly why it is read off the wire and never
  /// recomputed here. Still not permission to sell: that needs an assignment.
  final bool kycCleared;

  /// True when a bus operator created this identity rather than the agent
  /// self-registering. Provenance for the agent's benefit; grants nothing.
  final bool createdByOperator;

  final String? district;
  final String? municipality;
  final String? placeName;
  final String? businessName;
  final String? shopAddress;

  /// The code to display and share, preferring the current scheme. `null` when
  /// the agent has neither, which a screen must say out loud.
  String? get shareableCode => agentCode ?? legacyAgentId;

  /// `placeName, municipality, district` with the blanks dropped, or `null` when
  /// the agent has filled in none of them.
  String? get locationLine {
    final parts = [
      placeName,
      municipality,
      district,
    ].whereType<String>().where((part) => part.trim().isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Whether there is any outlet detail worth giving a card to.
  bool get hasOutletDetails =>
      outletType != null ||
      locationLine != null ||
      (businessName?.trim().isNotEmpty ?? false) ||
      (shopAddress?.trim().isNotEmpty ?? false);

  factory AgentIdentity.fromJson(Map<String, dynamic> json) {
    return AgentIdentity(
      agentCode: _string(json['agentCode']),
      legacyAgentId: _string(json['legacyAgentId']),
      scope: AgentScope.tryParse(_string(json['scope'])),
      outletType: AgentOutletType.tryParse(_string(json['outletType'])),
      kycStatus: AgentApplicationStatus.tryParse(_string(json['kycStatus'])),
      kycStatusLabel: _string(json['kycStatusLabel']),
      // Absent or non-boolean reads as false. Never default a clearance to true.
      kycCleared: json['kycCleared'] == true,
      createdByOperator: json['createdByOperator'] == true,
      district: _string(json['district']),
      municipality: _string(json['municipality']),
      placeName: _string(json['placeName']),
      businessName: _string(json['businessName']),
      shopAddress: _string(json['shopAddress']),
    );
  }

  /// Value equality so a refetch that changed nothing does not rebuild the card.
  @override
  bool operator ==(Object other) =>
      other is AgentIdentity &&
      other.agentCode == agentCode &&
      other.legacyAgentId == legacyAgentId &&
      other.scope == scope &&
      other.outletType == outletType &&
      other.kycStatus == kycStatus &&
      other.kycStatusLabel == kycStatusLabel &&
      other.kycCleared == kycCleared &&
      other.createdByOperator == createdByOperator &&
      other.district == district &&
      other.municipality == municipality &&
      other.placeName == placeName &&
      other.businessName == businessName &&
      other.shopAddress == shopAddress;

  @override
  int get hashCode => Object.hash(
    agentCode,
    legacyAgentId,
    scope,
    outletType,
    kycStatus,
    kycStatusLabel,
    kycCleared,
    createdByOperator,
    district,
    municipality,
    placeName,
    businessName,
    shopAddress,
  );
}

/// The payload for `GET /api/agent/me/code`.
///
/// Exists for [sharePayload]: the sentence that goes on a clipboard or into a
/// share sheet is composed server-side so the app, the agent web console and the
/// operator console all say the same thing. Composing it here would fork the
/// wording on the next copy change.
@immutable
class AgentCodeShare {
  const AgentCodeShare({
    required this.agentCode,
    required this.legacyAgentId,
    required this.sharePayload,
  });

  final String? agentCode;
  final String? legacyAgentId;

  /// `null` when the agent has no code at all — there is then nothing to share,
  /// and the caller must not substitute a sentence of its own.
  final String? sharePayload;

  factory AgentCodeShare.fromJson(Map<String, dynamic> json) {
    return AgentCodeShare(
      agentCode: _string(json['agentCode']),
      legacyAgentId: _string(json['legacyAgentId']),
      sharePayload: _string(json['sharePayload']),
    );
  }
}

/// Non-empty trimmed string, or `null`. Mongo writes `null` for unset optional
/// fields and the empty string for cleared ones; both mean "not provided".
String? _string(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
