/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — API paths
///
/// Every path below was read off the backend's own router files and is annotated
/// with its source. Nothing here is inferred, and nothing is added speculatively:
/// the redesign brief forbids inventing endpoints, so a screen that has no
/// contract yet gets an honest "unavailable" state rather than a guessed URL.
///
/// Mount points (`routes/indexRoute.js`):
///
///   /api                → routes/userRoutes/userRoutes.js
///   /api/auth/agent     → routes/authRoutes/agentAuthRoutes.js
///   /api/auth/activate  → routes/authRoutes/activateAuthRoutes.js
///   /api/agent          → routes/agentRoute/agentRoute.js
///   /api/conductor      → routes/conductorRoutes/conductorRoutes.js
///   /api/ticket         → routes/ticketRoutes/ticketRoutes.js
///
/// Paths are relative to [AppEnvironment.baseUrl], which is an origin only.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class ApiPaths {
  // ───────────────────────────────────────────────────────────────────────────
  // Shared session endpoints — userRoutes.js
  //
  // Used by every persona. `login` resolves the role from the X-App-Source
  // header, so one endpoint serves agents, conductors and drivers alike.
  // ───────────────────────────────────────────────────────────────────────────

  /// `POST` — body `{emailOrPhone, password}` + header `X-App-Source`.
  ///
  /// 200 → `{success, message, user, accessToken, activeRole}`, with the rotated
  /// refresh token in a `Set-Cookie` header.
  ///
  /// 200 is also returned for `{success, message, forcePasswordChange: true,
  /// tempToken}` — a success status with no session in it. Callers must check.
  static const String login = '/api/login';

  /// `POST` — body `{refreshToken}` (also accepted as a cookie). No auth header.
  ///
  /// 200 → `{success, message, accessToken}`. The rotated refresh token comes
  /// back **only** via `Set-Cookie`, and the presented one is deleted server-side
  /// on use, so the client must capture the new one or the next refresh fails.
  static const String refresh = '/api/refresh';

  /// `POST` — body `{refreshToken}`. Revokes the token and bumps the user's
  /// token version, invalidating outstanding access tokens.
  static const String logout = '/api/logout';

  /// `POST` — consumes a first-login temporary token, sets the user's chosen
  /// password, and returns a normal authenticated session.
  static const String changeForcedPassword = '/api/changeForcePassword';

  // ───────────────────────────────────────────────────────────────────────────
  // Account activation — activateAuthRoutes.js
  //
  // The path for conductors and drivers, whose accounts a bus owner creates.
  // They arrive with status `invited`, no password, and an SMS. Signing in
  // yields ACCOUNT_NOT_ACTIVATED until they complete this flow.
  // ───────────────────────────────────────────────────────────────────────────

  /// `POST` — body `{phone}`.
  static const String activateSendOtp = '/api/auth/activate/sendOTP';

  /// `POST` — body `{phone, otp, newPassword}`. Note the trailing slash: the
  /// route is registered as `router.post("/")` on the `/api/auth/activate` mount.
  static const String activate = '/api/auth/activate/';

  // ───────────────────────────────────────────────────────────────────────────
  // Agent self-registration and auth — agentAuthRoutes.js
  //
  // Agents are the only persona that can sign itself up. Conductors and drivers
  // are provisioned by a bus owner and must use activation instead.
  //
  // OTP endpoints take `phone`; login and the password-reset pair take
  // `emailOrPhone`. That difference is real — do not normalise the field names.
  // ───────────────────────────────────────────────────────────────────────────

  /// `POST` — body `{phone}`. Rate limited.
  static const String agentSendOtp = '/api/auth/agent/sendOTP';

  /// `POST` — body `{phone, otp}`.
  static const String agentVerifyOtp = '/api/auth/agent/verifyOTP';

  /// `POST` — body `{phone, purpose}`.
  static const String agentResendOtp = '/api/auth/agent/resendOTP';

  /// `POST` — creates the agent account after OTP verification.
  static const String agentRegister = '/api/auth/agent/register';

  /// `POST` — the agent-specific login. Prefer [login] with `X-App-Source:
  /// agent` so one code path serves all three personas.
  static const String agentLogin = '/api/auth/agent/login';

  static const String agentRefresh = '/api/auth/agent/refresh';
  static const String agentLogout = '/api/auth/agent/logout';

  /// `POST` — body `{emailOrPhone}`.
  static const String agentRequestPasswordReset =
      '/api/auth/agent/requestPasswordReset';

  /// `POST` — body `{emailOrPhone, otp}`.
  static const String agentVerifyOtpForReset =
      '/api/auth/agent/verifyOtpForReset';

  /// `POST` — body `{emailOrPhone, otp, newPassword}`.
  static const String agentResetPassword = '/api/auth/agent/resetPassword';

  /// `POST` — body `{emailOrPhone}`.
  static const String agentResendOtpForReset =
      '/api/auth/agent/resendOtpForReset';

  // ───────────────────────────────────────────────────────────────────────────
  // Agent workspace — agentRoute.js
  //
  // All require: auth + verifyRoleFromDB + agentMiddleware.
  // `profile` and `dashboard` additionally require requireApprovedAgent, so
  // they answer 403 APPLICATION_NOT_APPROVED (carrying `applicationStatus`)
  // until KYC clears.
  // ───────────────────────────────────────────────────────────────────────────

  /// `GET` — the agent's own identity: `agentCode`, `scope`, `outletType`,
  /// `kycStatus` + `kycStatusLabel`, `kycCleared`, the outlet fields, and an
  /// `assignments` summary. `PATCH` updates the editable subset (name, outlet
  /// type, district, municipality, placeName, businessName, shopAddress) and
  /// answers with the same shape.
  ///
  /// Deliberately **not** behind `requireApprovedAgent`: an agent must be able
  /// to read their own code and KYC state at every status, including DRAFT.
  /// That is the difference between this and [agentProfile].
  ///
  /// `kycCleared` is the server's answer to "does this agent's own verification
  /// permit selling". It is not permission to sell — that also needs an ACTIVE
  /// operator assignment. Never derive it client-side.
  static const String agentMe = '/api/agent/me';

  /// `GET` — the code alone, plus `sharePayload`: the exact sentence to put on a
  /// clipboard or into a share sheet, composed server-side so the app, the web
  /// agent console and the operator console all share one wording.
  static const String agentMeCode = '/api/agent/me/code';

  /// `GET` — every operator relationship owned by the signed-in agent.
  /// Invitations are readable before KYC so the agent can decide whether the
  /// work is worth completing verification for.
  static const String agentAssignments = '/api/agent/assignments';

  /// `POST` — the agent accepts their own still-live invitation.
  static String acceptAgentAssignment(String assignmentId) =>
      '$agentAssignments/$assignmentId/accept';

  /// `POST` — the agent declines their own still-live invitation. The optional
  /// request body is `{reason}` and the backend caps it at 500 characters.
  static String declineAgentAssignment(String assignmentId) =>
      '$agentAssignments/$assignmentId/decline';

  /// `POST` — saves a partial KYC application. Idempotent; safe to autosave.
  static const String agentApplicationSave = '/api/agent/application/save';

  /// `POST` — `multipart/form-data`. The file part is named **`file`** and is
  /// accompanied by a text field `documentType`.
  static const String agentApplicationDocument =
      '/api/agent/application/document';

  /// `POST` — body `{}`. Moves the application DRAFT → PENDING.
  static const String agentApplicationSubmit = '/api/agent/application/submit';

  /// `GET` — the KYC gate's data source. Readable at every application status,
  /// unlike [agentProfile] and [agentDashboard].
  static const String agentApplicationStatus = '/api/agent/application/status';

  /// `GET` — authenticated proxy that streams an uploaded document back. Used
  /// instead of a direct storage URL so documents are never publicly readable.
  static const String agentDocumentView = '/api/agent/documents/view';

  /// `GET` — approved agents only.
  static const String agentProfile = '/api/agent/profile';

  /// `GET` — approved agents only. Returns exactly eight scalars:
  /// `commissionBalance`, `totalOnlineBookings`, `totalCashBookings`,
  /// `totalCommissionEarned`, `totalCommissionSettled`, `lastBookingAt`,
  /// `commissionRate`, `agentType`.
  static const String agentDashboard = '/api/agent/dashboard';

  // ───────────────────────────────────────────────────────────────────────────
  // Conductor workspace — conductorRoutes.js
  //
  // Only two endpoints exist. There is no route that lists a conductor's
  // assigned trips, so the trip id has to come from elsewhere (see the
  // conductor workspace notes in docs/APP_PLAN.md).
  // ───────────────────────────────────────────────────────────────────────────

  /// `POST` — body `{ticketId, tripId}`.
  static const String conductorConfirmBoarding = '/api/conductor/confirmBoarding';

  /// `GET` — the passenger manifest for one trip.
  static String conductorManifest(String tripId) =>
      '/api/conductor/manifest/$tripId';

  // ───────────────────────────────────────────────────────────────────────────
  // Ticketing — ticketRoutes.js
  // ───────────────────────────────────────────────────────────────────────────

  /// `POST` — seat availability for a trip. `optionalAuth`, so it works before
  /// sign-in.
  ///
  /// Availability only. There is deliberately **no agent booking-creation path
  /// here**: every create route on this router is gated by
  /// `requireRole("passenger")`, so an agent token receives 403. Adding a
  /// speculative path would be inventing a contract.
  static const String ticketGetSeats = '/api/ticket/getSeats';
}
