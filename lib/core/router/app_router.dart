import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';

// ── Auth screens ──────────────────────────────────────────────────────────────
import 'package:shuvmarg_partner_app/features/auth/screens/splash_screen.dart';
import 'package:shuvmarg_partner_app/features/auth/screens/welcome_screen.dart';
import 'package:shuvmarg_partner_app/features/auth/screens/phone_entry_screen.dart';
import 'package:shuvmarg_partner_app/features/auth/screens/otp_verify_screen.dart';
import 'package:shuvmarg_partner_app/features/auth/screens/login_screen.dart';
import 'package:shuvmarg_partner_app/features/auth/screens/password_setup_screen.dart';
import 'package:shuvmarg_partner_app/features/auth/screens/forgot_password_screen.dart';
import 'package:shuvmarg_partner_app/features/auth/screens/new_password_screen.dart';

// ── Application flow ──────────────────────────────────────────────────────────
import 'package:shuvmarg_partner_app/features/application/screens/app_step1_screen.dart';
import 'package:shuvmarg_partner_app/features/application/screens/app_step2_screen.dart';
import 'package:shuvmarg_partner_app/features/application/screens/app_step3_screen.dart';
import 'package:shuvmarg_partner_app/features/application/screens/app_step4_screen.dart';
import 'package:shuvmarg_partner_app/features/application/screens/app_status_screen.dart';

// ── Agent shell + main screens ─────────────────────────────────────────────────
import 'package:shuvmarg_partner_app/features/agent/screens/agent_shell.dart';
import 'package:shuvmarg_partner_app/features/agent/screens/home_screen.dart';

// ── Booking flow ──────────────────────────────────────────────────────────────
import 'package:shuvmarg_partner_app/features/booking/screens/route_search_screen.dart';
import 'package:shuvmarg_partner_app/features/booking/screens/search_results_screen.dart';
import 'package:shuvmarg_partner_app/features/booking/screens/seat_map_screen.dart';
import 'package:shuvmarg_partner_app/features/booking/screens/passenger_details_screen.dart';
import 'package:shuvmarg_partner_app/features/booking/screens/payment_mode_screen.dart';
import 'package:shuvmarg_partner_app/features/booking/screens/payment_qr_screen.dart';
import 'package:shuvmarg_partner_app/features/booking/screens/booking_confirm_screen.dart';
import 'package:shuvmarg_partner_app/features/bookings/screens/my_bookings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // ── Splash ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Welcome ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      // ── Auth: Login ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Auth: Signup flow ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.phoneEntry,
        builder: (context, state) =>
            const PhoneEntryScreen(mode: PhoneEntryMode.signup),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (context, state) {
          // extra = { 'phone': String, 'purpose': String }
          final args  = state.extra as Map<String, dynamic>? ?? {};
          final phone   = args['phone'] as String? ?? '';
          final purpose = args['purpose'] as String? ?? 'REGISTRATION';
          return OtpVerifyScreen(phone: phone, purpose: purpose);
        },
      ),
      GoRoute(
        path: AppRoutes.passwordSetup,
        builder: (context, state) {
          // extra = {
          //   'phone':            String,
          //   'isExistingUser':   bool   (true = upgrade path, skip password),
          //   'existingUserName': String? (pre-fill name for existing users),
          // }
          final args            = state.extra as Map<String, dynamic>? ?? {};
          final phone           = args['phone']            as String? ?? '';
          final isExistingUser  = args['isExistingUser']   as bool?   ?? false;
          final existingName    = args['existingUserName'] as String?;
          return PasswordSetupScreen(
            phone:            phone,
            isExistingUser:   isExistingUser,
            existingUserName: existingName,
          );
        },
      ),

      // ── Auth: Forgot / Reset password ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.newPassword,
        builder: (context, state) {
          // extra = { 'phone': String, 'otp': String }
          final args  = state.extra as Map<String, dynamic>? ?? {};
          final phone = args['phone'] as String? ?? '';
          final otp   = args['otp']   as String? ?? '';
          return NewPasswordScreen(phone: phone, otp: otp);
        },
      ),

      // ── Application Steps ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.appStep1Personal,
        builder: (context, state) => const AppStep1Screen(),
      ),
      GoRoute(
        path: AppRoutes.appStep2Business,
        builder: (context, state) => const AppStep2Screen(),
      ),
      GoRoute(
        path: AppRoutes.appStep3Documents,
        builder: (context, state) => const AppStep3Screen(),
      ),
      GoRoute(
        path: AppRoutes.appStep4Settlement,
        builder: (context, state) => const AppStep4Screen(),
      ),
      GoRoute(
        path: AppRoutes.appStatus,
        builder: (context, state) => const AppStatusScreen(),
      ),

      // ── Agent Shell (with bottom nav) ────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AgentShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.agentHome,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const RouteSearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.myBookings,
            builder: (context, state) => const MyBookingsScreen(),
          ),
        ],
      ),

      // ── Booking Flow (full-screen, outside shell) ─────────────────────────────
      GoRoute(
        path: AppRoutes.searchResults,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return SearchResultsScreen(
            from: args['from'] ?? '',
            to:   args['to']   ?? '',
            date: args['date'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.seatMap,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return SeatMapScreen(tripData: args);
        },
      ),
      GoRoute(
        path: AppRoutes.passengerDetails,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return PassengerDetailsScreen(bookingData: args);
        },
      ),
      GoRoute(
        path: AppRoutes.paymentMode,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return PaymentModeScreen(bookingData: args);
        },
      ),
      GoRoute(
        path: AppRoutes.paymentQr,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return PaymentQrScreen(bookingData: args);
        },
      ),
      GoRoute(
        path: AppRoutes.bookingConfirm,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return BookingConfirmScreen(bookingResult: args);
        },
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A1F1C),
      body: Center(
        child: Text(
          'Page not found: ${state.error}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
});
