/// All named route paths for the partner app.
/// Used by go_router. Keep in one place to avoid magic strings.
class AppRoutes {
  AppRoutes._();

  // ── Pre-auth ──────────────────────────────────────────────────────────────
  static const String splash              = '/';
  static const String welcome             = '/welcome';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login               = '/auth/login';
  static const String phoneEntry          = '/auth/phone';   // signup — phone step
  static const String otpVerify           = '/auth/otp';     // signup & forgot-pass OTP
  static const String passwordSetup       = '/auth/setup';   // post-OTP registration
  static const String forgotPassword      = '/auth/forgot';  // forgot password phone entry
  static const String newPassword         = '/auth/new-password'; // reset password form

  // ── Application steps (DEFAULT agent self-apply flow) ─────────────────────
  static const String appStep1Personal   = '/apply/step1';
  static const String appStep2Business   = '/apply/step2';
  static const String appStep3Documents  = '/apply/step3';
  static const String appStep4Settlement = '/apply/step4';
  static const String appStatus          = '/apply/status';

  // ── Post-approval — Agent Shell (with bottom nav) ─────────────────────────
  static const String agentHome          = '/home';
  static const String search             = '/book/search';
  static const String myBookings         = '/bookings';

  // ── Booking Flow (full-screen, outside shell) ─────────────────────────────
  static const String searchResults      = '/book/results';
  static const String seatMap            = '/book/seats';
  static const String passengerDetails   = '/book/passenger';
  static const String paymentMode        = '/book/payment-mode';
  static const String paymentQr          = '/book/payment-qr';
  static const String bookingConfirm     = '/book/confirm';

  // ── Other ─────────────────────────────────────────────────────────────────
  static const String bookingDetail      = '/bookings/:id';
  static const String wallet             = '/wallet';
  static const String withdraw           = '/wallet/withdraw';
  static const String analytics          = '/analytics';
  static const String profile            = '/profile';
  static const String support            = '/support';
  static const String conductorHome      = '/conductor/home';
  static const String manifest           = '/conductor/manifest';
  static const String roleSelector       = '/role-select';
}
