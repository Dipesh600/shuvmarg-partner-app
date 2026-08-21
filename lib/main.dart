import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuvmarg_partner_app/core/design/design.dart';
import 'package:shuvmarg_partner_app/features/design_gallery/design_gallery_screen.dart';
import 'package:shuvmarg_partner_app/features/shell/workspace_shell.dart';
import 'package:shuvmarg_partner_app/shared/ui/ui.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — entry point
///
/// FOUNDATION BUILD. This wires up the design system and the workspace shell
/// ported from the agent web (`shuvmarg_partner_web`). Feature screens (auth,
/// KYC application, booking, earnings) are intentionally not present yet.
///
/// This file imports **only** the new `core/design`, `shared/ui` and
/// `features/shell` code — nothing from the previous implementation — so the
/// old tree can be deleted without touching anything here.
///
/// Routing note: go_router is still a dependency and should own navigation once
/// real screens exist. While the shell has four placeholder tabs, an
/// `IndexedStack` keeps the foundation reviewable without committing to a route
/// table that will be rewritten anyway.
/// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Light cream canvas → dark status bar icons. The previous theme set light
  // icons for an AMOLED dark UI; keeping that would render them invisible.
  SystemChrome.setSystemUIOverlayStyle(appSystemOverlay);

  runApp(const ProviderScope(child: ShuvmargPartnerApp()));
}

class ShuvmargPartnerApp extends StatelessWidget {
  const ShuvmargPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shuvmarg Partner',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const WorkspaceRoot(),
    );
  }
}

/// Hosts the four workspace destinations behind the floating bottom nav.
class WorkspaceRoot extends StatefulWidget {
  const WorkspaceRoot({super.key});

  @override
  State<WorkspaceRoot> createState() => _WorkspaceRootState();
}

class _WorkspaceRootState extends State<WorkspaceRoot> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return WorkspaceShell(
      currentIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      child: IndexedStack(
        index: _index,
        children: const [
          DesignGalleryScreen(),
          _PlaceholderScreen(
            title: 'Bookings',
            icon: Icons.confirmation_number_rounded,
          ),
          _PlaceholderScreen(
            title: 'Customers',
            icon: Icons.people_alt_rounded,
          ),
          _PlaceholderScreen(
            title: 'Earnings',
            icon: Icons.account_balance_wallet_rounded,
          ),
        ],
      ),
    );
  }
}

/// Stand-in for a destination whose screen hasn't been built yet.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppCard(
              child: Column(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(title, style: AppText.titleLg),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Not built yet. The design foundation is in place — this '
                    'screen comes next.',
                    style: AppText.bodySm,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.navReservedSpace),
          ],
        ),
      ),
    );
  }
}
