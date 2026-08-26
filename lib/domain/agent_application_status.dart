/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — agent KYC application status
///
/// The lifecycle of an agent's onboarding application, as the backend reports it
/// through `GET /api/agent/application/status` and in the `applicationStatus`
/// field of a 403 `APPLICATION_NOT_APPROVED` response.
///
/// Wire values are pinned to the backend's own set — verified against
/// `middleware/requireApprovedAgent.js`, whose `messageMap` keys are exactly
/// DRAFT / PENDING / MORE_INFO / REJECTED / SUSPENDED, plus APPROVED for the
/// pass-through case, and against `src/shared/identity/agent-enums.js`, which
/// adds PHONE_VERIFIED and VERIFIED_BASIC. A missing application row is
/// `NO_APPLICATION` on the wire and is represented here as a `null` status, not
/// a member — there is no application to have a status yet.
///
/// ONE FIELD, TWO STATE MACHINES. The backend runs both an operator-owned and a
/// platform-owned agent through the same `applicationStatus` field, because
/// adding a second status column would give one question two answers:
///
///   OPERATOR  DRAFT → PHONE_VERIFIED → VERIFIED_BASIC → SUSPENDED
///   PLATFORM  DRAFT → PENDING → MORE_INFO → APPROVED | REJECTED → SUSPENDED
///
/// So this enum is the union of both paths, and which members are reachable
/// depends on the agent's [AgentScope]. Do not read a member as evidence of a
/// scope, and do not decide *here* whether a status permits selling — that is
/// scope-dependent and the server answers it with `kycCleared` on
/// `GET /api/agent/me`.
///
/// This enum is intentionally UI-free: the workspace decides what to *show* for
/// each status; this only says what the status *is*.
/// ─────────────────────────────────────────────────────────────────────────────
enum AgentApplicationStatus {
  /// Saved but not submitted. The agent can keep editing and then submit.
  draft('DRAFT'),

  /// Operator path: the agent proved they hold the phone number their operator
  /// registered. Not yet cleared for anything.
  phoneVerified('PHONE_VERIFIED'),

  /// Operator path, terminal-good: name and phone confirmed, which is the whole
  /// of KYC for an agent the platform never pays. Clears them to be assigned by
  /// a bus operator — it does **not** clear the platform workspace, which still
  /// requires APPROVED (see [canAccessWorkspace]).
  verifiedBasic('VERIFIED_BASIC'),

  /// Submitted and awaiting review. Read-only for the agent.
  pending('PENDING'),

  /// A reviewer asked for corrections. The agent edits and resubmits.
  moreInfo('MORE_INFO'),

  /// Cleared. The agent workspace (profile, dashboard, bookings) unlocks.
  approved('APPROVED'),

  /// Declined. Reapplication may be allowed after a cooldown, unless the
  /// backend also flags `isPermanentlyRejected`.
  rejected('REJECTED'),

  /// An approved agent whose access was later withdrawn by an admin.
  suspended('SUSPENDED');

  const AgentApplicationStatus(this.wire);

  /// Exact string the backend uses in `applicationStatus`.
  final String wire;

  /// Parses a backend `applicationStatus` value.
  ///
  /// Returns `null` for `null`, an empty string, `NO_APPLICATION`, or anything
  /// unrecognised. A `null` here means "no usable application status" — the
  /// caller treats that as not-yet-approved, never as approved.
  static AgentApplicationStatus? tryParse(String? value) {
    if (value == null) return null;
    final normalised = value.trim().toUpperCase();
    if (normalised.isEmpty) return null;
    for (final status in AgentApplicationStatus.values) {
      if (status.wire == normalised) return status;
    }
    return null;
  }

  /// True only for [approved].
  bool get isApproved => this == AgentApplicationStatus.approved;

  /// Whether the approved-only endpoints (`profile`, `dashboard`) and the
  /// booking workspace are reachable. Only an approved application clears the
  /// gate; every other status — and a missing application — keeps it closed.
  ///
  /// [verifiedBasic] deliberately does **not** clear it. `requireApprovedAgent`
  /// tests `applicationStatus !== "APPROVED"`, so an operator-owned agent at
  /// VERIFIED_BASIC still gets 403 from those two endpoints. Returning true here
  /// would make the app send requests it knows will be refused.
  bool get canAccessWorkspace => isApproved;

  /// Human-readable name for status chips and gate copy.
  ///
  /// Short by design — a chip has no room for a sentence. `GET /api/agent/me`
  /// also returns `kycStatusLabel`, a fuller line written for the agent; prefer
  /// that where there is space, and use this for the pill beside it.
  String get label => switch (this) {
    AgentApplicationStatus.draft => 'Draft',
    AgentApplicationStatus.phoneVerified => 'Phone verified',
    AgentApplicationStatus.verifiedBasic => 'Verified',
    AgentApplicationStatus.pending => 'Under review',
    AgentApplicationStatus.moreInfo => 'More info needed',
    AgentApplicationStatus.approved => 'Approved',
    AgentApplicationStatus.rejected => 'Rejected',
    AgentApplicationStatus.suspended => 'Suspended',
  };
}
