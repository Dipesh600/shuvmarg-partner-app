import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_environment.dart';
import '../core/design/app_theme.dart';
import '../shared/session/session_providers.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — bootstrap
///
/// Everything that must complete before the first frame, in order:
///
///   1. Bind the framework.
///   2. Lock orientation and set the status-bar style (the brand header paints
///      behind the status bar, so the icons must be light).
///   3. Assert the environment resolves — fail fast on a misconfigured build
///      rather than at the first network call.
///   4. Build the provider container, migrate any legacy plaintext credentials
///      off the old store, then read the persisted session so the session
///      controller can build synchronously and the router has a real answer on
///      the very first redirect.
///
/// Returns the primed container for `main` to host with an
/// [UncontrolledProviderScope].
/// ─────────────────────────────────────────────────────────────────────────────
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(appSystemOverlay);

  // Resolves the base URL and throws for an unconfigured flavor. Doing it here
  // turns a deployment mistake into an immediate, obvious startup failure.
  AppEnvironment.assertValid();

  final container = ProviderContainer();
  final store = container.read(sessionStoreProvider);

  // Migrate off the old, insecure SharedPreferences store before reading, so a
  // returning user's session moves into secure storage exactly once.
  await store.purgeLegacyPlaintextCredentials();

  // Prime SessionStore.cached; SessionController.build() reads it synchronously,
  // which is what keeps the router from ever seeing an async session.
  await store.read();

  return container;
}
