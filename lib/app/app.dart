import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/app_theme.dart';
import 'router/app_router.dart';

/// The root widget. Nothing but a themed [MaterialApp.router] over the session-
/// driven [routerProvider]; all navigation and guarding happen inside the
/// router, all styling inside [buildAppTheme].
class ShuvmargPartnerApp extends ConsumerWidget {
  const ShuvmargPartnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Shuvmarg Partner',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
