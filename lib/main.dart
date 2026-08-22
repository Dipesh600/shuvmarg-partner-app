import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — entry point
///
/// [bootstrap] does the async startup work and returns a container already
/// primed with the persisted session. Hosting that same container with an
/// [UncontrolledProviderScope] (rather than a plain `ProviderScope`) means the
/// session the router reads on its first redirect is the one we just restored —
/// no second read, no first-frame flash of the signed-out state for a returning
/// user.
/// ─────────────────────────────────────────────────────────────────────────────
Future<void> main() async {
  final container = await bootstrap();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ShuvmargPartnerApp(),
    ),
  );
}
