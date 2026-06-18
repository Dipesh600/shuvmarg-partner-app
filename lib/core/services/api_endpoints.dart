/// Shuvmarg Partner App — API Endpoints
/// All auth calls use X-App-Source: agent (applied in ApiService interceptor).

enum DevTarget { macDesktop, androidEmu, physicalDevice, production }

class ApiEndpoints {
  ApiEndpoints._();

  // ── Switch this to change the environment ─────────────────────────────────
  // macDesktop    → 127.0.0.1:7012   (flutter run -d macos / iOS sim)
  // androidEmu    → 10.0.2.2:7012    (Android Studio emulator)
  // physicalDevice → LAN IP          (real phone on same Wi-Fi)
  // production    → api.shuvmarg.com
  static const _env = DevTarget.physicalDevice;

  static String get baseUrl {
    switch (_env) {
      case DevTarget.macDesktop:
        return 'http://127.0.0.1:7012';
      case DevTarget.androidEmu:
        return 'http://10.0.2.2:7012';
      case DevTarget.physicalDevice:
        return 'http://10.232.45.245:7012'; // Mac LAN IP — phone must be on same Wi-Fi
      case DevTarget.production:
        return 'https://api.shuvmarg.com';
    }
  }

  static const String _api = '/api';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static String get sendPhoneOtp         => '$baseUrl$_api/sendPhoneOTP';
  static String get verifyPhoneOtp       => '$baseUrl$_api/verifyPhoneOTP';
  static String get completeRegistration => '$baseUrl$_api/completeRegistration';
  static String get login                => '$baseUrl$_api/login';
  static String get resendOtp            => '$baseUrl$_api/resendOtp';
  static String get requestPasswordReset => '$baseUrl$_api/requestPasswordReset';
  static String get verifyOtpForReset    => '$baseUrl$_api/verifyOtpForReset';
  static String get resetPassword        => '$baseUrl$_api/resetPassword';
  static String get refreshToken         => '$baseUrl$_api/refresh';
  static String get logout               => '$baseUrl$_api/logout';
  static String get getUserDetail        => '$baseUrl$_api/getUserDetail';
  static String get updateProfile        => '$baseUrl$_api/updateProfile';
  static String get updatePassword       => '$baseUrl$_api/updatepassword';

  // ── Agent Application (KYC) ───────────────────────────────────────────────
  static String get agentAppSave     => '$baseUrl$_api/agent/application/save';
  static String get agentAppDocument => '$baseUrl$_api/agent/application/document';
  static String get agentAppSubmit   => '$baseUrl$_api/agent/application/submit';
  static String get agentAppStatus   => '$baseUrl$_api/agent/application/status';

  // ── Agent Profile & Dashboard (post-approval) ─────────────────────────────
  static String get agentProfile   => '$baseUrl$_api/agent/profile';
  static String get agentDashboard => '$baseUrl$_api/agent/dashboard';

  // ── Ticket / Booking ──────────────────────────────────────────────────────
  static String get searchTrips    => '$baseUrl$_api/public/searchTrips';
  static String get getSeats       => '$baseUrl$_api/ticket/getSeats';
  static String get prepareBooking => '$baseUrl$_api/ticket/prepareBooking';
  static String get confirmBooking => '$baseUrl$_api/ticket/confirmBooking';
  static String get stopSearch     => '$baseUrl$_api/public/stops/search';
}
