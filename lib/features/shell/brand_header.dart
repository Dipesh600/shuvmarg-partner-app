import 'package:flutter/material.dart';

import '../../core/design/design.dart';

/// Brand-header layout: a brand-coloured bleed at the top of the screen with a
/// white content sheet whose rounded top corners overlap it.
///
/// This is the agent web's mobile dashboard treatment — a brand header bleed
/// with a `rounded-t-[32px]` content sheet sitting over it. The orange also
/// paints behind the status bar, so the screen reads as one continuous surface
/// rather than a coloured strip below a white gap.
///
/// Pair with [WorkspaceShell] for tabbed screens, or use standalone for
/// full-screen flows (auth, KYC) that have no bottom nav.
class BrandHeaderScaffold extends StatelessWidget {
  const BrandHeaderScaffold({
    super.key,
    required this.header,
    required this.child,
    this.headerPadding,
  });

  /// Content rendered on the brand-coloured bleed. Text and icons here must be
  /// white — see [AppColors.textOnPrimary].
  final Widget header;

  /// Content rendered inside the white sheet.
  final Widget child;

  final EdgeInsetsGeometry? headerPadding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // Paints behind the status bar so the bleed is uninterrupted.
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding:
                  headerPadding ??
                  const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.xs,
                    AppSpacing.gutter,
                    AppSpacing.xl,
                  ),
              child: header,
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: AppDecorations.sheet,
                // Keeps scrolling content from painting over the 32px corners.
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The greeting block the agent web shows at the top of the mobile dashboard:
/// a muted salutation with the agent's name picked out in gold.
class BrandGreeting extends StatelessWidget {
  const BrandGreeting({
    super.key,
    required this.salutation,
    required this.name,
    this.trailing,
  });

  /// e.g. "Good morning,"
  final String salutation;

  /// The agent's display name — rendered in [AppColors.goldLight], the one
  /// accent the web allows on a brand-filled surface.
  final String name;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                salutation,
                style: AppText.bodySm.copyWith(
                  color: AppColors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: AppText.display3.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Circular action button sized for the brand header (notifications, avatar).
///
/// Web equivalent is a translucent white circle on the coloured bar.
class BrandHeaderAction extends StatelessWidget {
  const BrandHeaderAction({
    super.key,
    required this.icon,
    this.onTap,
    this.showDot = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;

  /// Unread indicator, matching the web's notification dot.
  final bool showDot;

  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: AppColors.navHover,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.white),
            if (showDot)
              Positioned(
                top: 10,
                right: 11,
                child: Container(
                  height: 7,
                  width: 7,
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
