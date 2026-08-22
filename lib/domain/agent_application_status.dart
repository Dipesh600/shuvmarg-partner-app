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
/// pass-through case. A missing application row is `NO_APPLICATION` on the wire
/// and is represented here as a `null` status, not a member — there is no
/// application to have a status yet.
///
/// This enum is intentionally UI-free: the workspace decides what to *show* for
/// each status; this only says what the status *is*.
/// ─────────────────────────────────────────────────────────────────────────────
enum AgentApplicationStatus {
  /// Saved but not submitted. The agent can keep editing and then submit.
  draft('DRAFT'),

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
  bool get canAccessWorkspace => isApproved;

  /// Human-readable name for status chips and gate copy.
  String get label => switch (this) {
    AgentApplicationStatus.draft => 'Draft',
    AgentApplicationStatus.pending => 'Under review',
    AgentApplicationStatus.moreInfo => 'More info needed',
    AgentApplicationStatus.approved => 'Approved',
    AgentApplicationStatus.rejected => 'Rejected',
    AgentApplicationStatus.suspended => 'Suspended',
  };
}
