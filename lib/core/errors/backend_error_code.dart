/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — backend error codes
///
/// The API returns machine-readable `errorCode` strings alongside its human
/// `message`. Branching on the code (not on the prose) is what lets a screen
/// react correctly — send a suspended agent to a support screen, send an
/// unapproved one back to KYC, offer "continue with OTP" to an account that has
/// no password.
///
/// The previous implementation threw `Exception('$message')`, so every code was
/// destroyed at the network boundary and every screen showed the same red text.
/// That is the defect this enum exists to prevent.
///
/// Only codes reachable from **this app's** endpoints are listed. The backend
/// defines many more (booking, payment, admin, seat-layout); enumerating those
/// would imply we call them. Anything unlisted surfaces as [unknown] with its
/// raw string preserved, so nothing is silently swallowed.
/// ─────────────────────────────────────────────────────────────────────────────
enum BackendErrorCode {
  // ── Account status — the account exists but cannot be used ────────────────
  accountDeleted('ACCOUNT_DELETED'),
  accountBanned('ACCOUNT_BANNED'),
  accountSuspended('ACCOUNT_SUSPENDED'),
  accountInactive('ACCOUNT_INACTIVE'),
  accountDeactivated('ACCOUNT_DEACTIVATED'),
  accountRestricted('ACCOUNT_RESTRICTED'),

  /// Bus-owner-provisioned conductors and drivers land here: the owner created
  /// the account, the user has not yet set a password via the activation SMS.
  /// Recovery is the `/api/auth/activate` flow, not registration.
  accountNotActivated('ACCOUNT_NOT_ACTIVATED'),

  /// Five failed passwords → locked 15 minutes. Arrives as HTTP 429.
  accountLocked('ACCOUNT_LOCKED'),

  // ── Credentials and session ──────────────────────────────────────────────
  /// Account was created by phone OTP and has no password hash. The UI should
  /// offer phone verification rather than repeating the password prompt.
  passwordNotSet('PASSWORD_NOT_SET'),

  /// A temporary password must be replaced before anything else. Note this also
  /// arrives on a **200** as `forcePasswordChange: true` + `tempToken`.
  forcePasswordChange('FORCE_PASSWORD_CHANGE'),

  /// Server-side token version was bumped (logout-everywhere, password change).
  /// Refresh cannot recover this; the user must sign in again.
  sessionInvalidated('SESSION_INVALIDATED'),
  invalidTokenPurpose('INVALID_TOKEN_PURPOSE'),
  roleRevoked('ROLE_REVOKED'),
  loginRateLimit('LOGIN_RATE_LIMIT'),

  // ── Role selection ───────────────────────────────────────────────────────
  /// Credentials are valid but the account does not hold the role named by
  /// `X-App-Source` — e.g. a passenger signing in on the conductor tab.
  roleNotRegistered('ROLE_NOT_REGISTERED'),
  roleNotFound('ROLE_NOT_FOUND'),
  roleMismatch('ROLE_MISMATCH'),

  /// The access token's `activeRole` is not permitted on this route.
  insufficientRole('INSUFFICIENT_ROLE'),

  // ── Registration ─────────────────────────────────────────────────────────
  roleAlreadyRegistered('ROLE_ALREADY_REGISTERED'),
  phoneAlreadyRegistered('PHONE_ALREADY_REGISTERED'),
  agentAlreadyExists('AGENT_ALREADY_EXISTS'),
  passwordRequiredForRoleUpgrade('PASSWORD_REQUIRED_FOR_ROLE_UPGRADE'),

  // ── OTP ──────────────────────────────────────────────────────────────────
  otpSendBlocked('OTP_SEND_BLOCKED'),
  otpCooldown('OTP_COOLDOWN'),
  otpSendCooldown('OTP_SEND_COOLDOWN'),
  otpSendIpRateLimit('OTP_SEND_IP_RATE_LIMIT'),
  otpVerifyRateLimit('OTP_VERIFY_RATE_LIMIT'),
  invalidOtp('INVALID_OTP'),
  invalidOtpLength('INVALID_OTP_LENGTH'),
  invalidPhone('INVALID_PHONE'),
  missingPhone('MISSING_PHONE'),
  missingVerifyInput('MISSING_VERIFY_INPUT'),
  smsDeliveryFailed('SMS_DELIVERY_FAILED'),
  activationRoleRequired('ACTIVATION_ROLE_REQUIRED'),
  invitationNotFound('INVITATION_NOT_FOUND'),
  accountAlreadyActive('ACCOUNT_ALREADY_ACTIVE'),
  activationNotAvailable('ACTIVATION_NOT_AVAILABLE'),
  driverAccountNotFound('DRIVER_ACCOUNT_NOT_FOUND'),
  driverAccountInvited('DRIVER_ACCOUNT_INVITED'),
  driverAccountUnavailable('DRIVER_ACCOUNT_UNAVAILABLE'),

  // ── Agent KYC application ────────────────────────────────────────────────
  /// Authenticated as an agent, but no application row exists yet → start KYC.
  noApplication('NO_APPLICATION'),

  /// Application exists but is not APPROVED. The payload carries
  /// `applicationStatus`, so the gate screen needs no second request.
  applicationNotApproved('APPLICATION_NOT_APPROVED'),
  applicationError('APPLICATION_ERROR'),

  /// Rejected applicants must wait 24 h from `rejectedAt` before reapplying.
  reapplyTooSoon('REAPPLY_TOO_SOON'),

  /// Rejected with `isPermanentlyRejected` — reapplying will never succeed.
  permanentlyRejected('PERMANENTLY_REJECTED'),

  noProfile('NO_PROFILE'),
  profileNotApproved('PROFILE_NOT_APPROVED'),

  // ── Generic ──────────────────────────────────────────────────────────────
  validationError('VALIDATION_ERROR'),

  /// Any code not listed above. [Failure.rawCode] keeps the original string so
  /// it can still be logged and reported.
  unknown('');

  const BackendErrorCode(this.wire);

  /// Exact string the backend puts in the `errorCode` field.
  final String wire;

  static final Map<String, BackendErrorCode> _byWire = {
    for (final code in BackendErrorCode.values)
      if (code != BackendErrorCode.unknown) code.wire: code,
  };

  /// Maps a raw `errorCode` string, falling back to [unknown].
  static BackendErrorCode parse(String? value) {
    if (value == null || value.trim().isEmpty) return BackendErrorCode.unknown;
    return _byWire[value.trim().toUpperCase()] ?? BackendErrorCode.unknown;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Groupings the UI branches on
  // ───────────────────────────────────────────────────────────────────────────

  /// The account's standing blocks normal sign-in. Most require support;
  /// [accountNotActivated] is the deliberate self-service exception.
  bool get isAccountBlocked => const {
    accountDeleted,
    accountBanned,
    accountSuspended,
    accountInactive,
    accountDeactivated,
    accountRestricted,
    accountNotActivated,
    driverAccountInvited,
    driverAccountUnavailable,
  }.contains(this);

  /// Re-authentication is the only recovery — clear the session and go to login.
  bool get requiresReauthentication => const {
    sessionInvalidated,
    invalidTokenPurpose,
    roleRevoked,
  }.contains(this);

  /// The agent's KYC application is the blocker, not their credentials.
  bool get isApplicationGate => const {
    noApplication,
    applicationNotApproved,
    profileNotApproved,
    noProfile,
  }.contains(this);

  /// A rate limit or cooldown — the correct UI is a countdown, not an error.
  bool get isThrottled => const {
    accountLocked,
    loginRateLimit,
    otpSendBlocked,
    otpCooldown,
    otpSendCooldown,
    otpSendIpRateLimit,
    otpVerifyRateLimit,
  }.contains(this);
}
