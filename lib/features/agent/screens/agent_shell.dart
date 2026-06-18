import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';

class AgentShell extends StatelessWidget {
  final Widget child;
  const AgentShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Home', route: AppRoutes.agentHome),
    _TabItem(icon: Icons.confirmation_number_outlined, label: 'Book', route: AppRoutes.search),
    _TabItem(icon: Icons.list_alt_rounded, label: 'Bookings', route: AppRoutes.myBookings),
    // Wallet placeholder — Phase 2
    _TabItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', route: AppRoutes.agentHome),
  ];

  int _activeIndex(String location) {
    if (location.startsWith(AppRoutes.myBookings)) return 2;
    if (location.startsWith(AppRoutes.search)) return 1;
    if (location == AppRoutes.agentHome) return 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final activeIdx = _activeIndex(location);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: child,
      bottomNavigationBar: _AppBottomNav(tabs: _tabs, activeIndex: activeIdx),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  final List<_TabItem> tabs;
  final int activeIndex;
  const _AppBottomNav({required this.tabs, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xE8003D38), // deep emerald, 91% opaque
        borderRadius: BorderRadius.circular(AppRadius.nav),
        border: Border.all(color: AppColors.stroke),
        boxShadow: AppShadows.bottomNav,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final isActive = i == activeIndex;
          return _NavItem(
            icon: tab.icon,
            label: tab.label,
            isActive: isActive,
            onTap: () {
              if (!isActive) context.go(tab.route);
            },
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentLime.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.navActive : AppColors.navInactive,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.navActive : AppColors.navInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String route;
  const _TabItem({required this.icon, required this.label, required this.route});
}
