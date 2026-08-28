import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/app_role.dart';
import '../../features/agent/agent_home_screen.dart';
import '../../features/conductor/conductor_home_screen.dart';
import '../../features/driver/driver_home_screen.dart';
import '../../features/entry/sign_in_screen.dart';
import '../../features/entry/force_password/force_password_route.dart';
import '../../features/entry/force_password/force_password_screen.dart';
import '../../features/entry/splash_screen.dart';
import '../../features/entry/welcome_screen.dart';
import '../../features/entry/wrong_app_screen.dart';
import '../../shared/session/session_providers.dart';
import '../../shared/session/session_state.dart';
import 'guards.dart';
import 'routes.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — router
///
/// One [GoRouter], driven by the session. The security-relevant decisions live
/// in the pure [sessionRedirect] guard (see `guards.dart`); this file only wires
/// that guard to the session state and lists the routes.
/// ─────────────────────────────────────────────────────────────────────────────

/// Bridges Riverpod's [sessionControllerProvider] to go_router's
/// [Listenable]-based refresh.
///
/// go_router re-runs its `redirect` whenever this notifies. We forward every
/// session change to it so a sign-in, sign-out, or expiry re-evaluates the guard
/// immediately, rather than waiting for the next manual navigation.
class RouterRefreshNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}

/// The refresh bridge, kept alive for the app's lifetime. Listening (not
/// watching) the session means this provider is built once and simply pushes
/// changes into the notifier — it never itself rebuilds.
final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  ref.listen<SessionState>(
    sessionControllerProvider,
    (_, _) => notifier.bump(),
  );
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// The app router. Built once; its `redirect` reads the live session on every
/// evaluation, and [RouterRefreshNotifier] triggers those evaluations.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    // The single global guard. `matchedLocation` is the path without query, so
    // role isolation is decided on the route alone.
    redirect: (context, state) => sessionRedirect(
      ref.read(sessionControllerProvider),
      state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        // Guards the role parameter before the screen builds: an absent or
        // unrecognised role has no valid workspace to sign into, so bounce to
        // the picker rather than render a form that cannot submit.
        redirect: (context, state) {
          final role = AppRole.tryParse(state.uri.queryParameters['role']);
          return role == null ? AppRoutes.welcome : null;
        },
        builder: (context, state) =>
            SignInScreen(roleWire: state.uri.queryParameters['role']),
      ),
      GoRoute(
        path: AppRoutes.forcePassword,
        builder: (context, state) => ForcePasswordScreen(
          args: state.extra is ForcePasswordArgs
              ? state.extra! as ForcePasswordArgs
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.wrongApp,
        builder: (context, state) => const WrongAppScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentHome,
        builder: (context, state) => const AgentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.conductorHome,
        builder: (context, state) => const ConductorHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverHome,
        builder: (context, state) => const DriverHomeScreen(),
      ),
    ],
  );
});
