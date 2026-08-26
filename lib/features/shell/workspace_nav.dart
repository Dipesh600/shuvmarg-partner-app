import 'package:flutter/material.dart';

import '../../core/design/design.dart';

/// A destination on the floating bottom navigation bar.
///
/// The agent web exposes exactly four workspace destinations across all of its
/// nav variants (desktop sidebar, tablet rail, mobile bar); Settings and Sign
/// out live in the avatar popover instead, deliberately kept off the bar.
class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

/// The canonical workspace destinations, in the web's order.
const List<NavDestination> workspaceDestinations = [
  NavDestination(
    label: 'Overview',
    icon: Icons.grid_view_rounded,
    route: '/dashboard',
  ),
  NavDestination(
    label: 'Bookings',
    icon: Icons.confirmation_number_rounded,
    route: '/dashboard/bookings',
  ),
  NavDestination(
    label: 'Customers',
    icon: Icons.people_alt_rounded,
    route: '/dashboard/customers',
  ),
  NavDestination(
    label: 'Earnings',
    icon: Icons.account_balance_wallet_rounded,
    route: '/dashboard/earnings',
  ),
];

/// Floating brand-filled bottom navigation.
///
/// Web reference (`WorkspaceNav.tsx`):
/// ```jsx
/// <nav className="md:hidden fixed bottom-6 left-4 right-4 h-16
///                 bg-[#D96B62] rounded-2xl
///                 shadow-[0_8px_32px_rgba(217,107,98,0.3)]
///                 flex flex-row items-center justify-around px-2">
/// ```
///
/// Two details carried over deliberately:
///  • the bar **floats** — it is inset from all three edges, never edge-to-edge
///  • the active state **inverts** to a white pill with brand-coloured content,
///    rather than merely tinting the icon
class WorkspaceNavBar extends StatelessWidget {
  const WorkspaceNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.destinations = workspaceDestinations,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.navSideInset,
        right: AppSpacing.navSideInset,
        // Respect the home indicator / gesture area, but never sit closer than
        // the web's 24px float.
        bottom: AppSpacing.navBottomInset,
      ),
      child: Container(
        height: AppSpacing.navHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: AppDecorations.navBar,
        child: Row(
          children: [
            // Equal slots rather than `spaceAround`: with intrinsic widths the
            // four labels need ~308px, which overflows the bar on a 320pt
            // device. Each item still hugs its content inside its slot, so the
            // active pill keeps the web's shrink-to-fit look.
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _NavItem(
                  destination: destinations[i],
                  selected: i == currentIndex,
                  onTap: () => onDestinationSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Web: active → `bg-white text-[#D96B62] font-semibold shadow-sm`
    //      idle   → `text-white/80`
    final foreground = selected ? AppColors.primary : AppColors.navInactive;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // Hugs its content inside the equal-width slot handed down by the Row.
        child: Center(
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.smooth,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              borderRadius: AppRadius.pillRadius,
              boxShadow: selected ? AppShadows.card : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(destination.icon, size: 20, color: foreground),
                const SizedBox(height: 2),
                Text(
                  destination.label,
                  style: AppText.navLabel.copyWith(
                    color: foreground,
                    // Web bolds the active label. Weight changes reflow text,
                    // so both weights must still fit the slot — hence ellipsis.
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
