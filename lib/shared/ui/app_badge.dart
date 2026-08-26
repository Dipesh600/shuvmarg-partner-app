import 'package:flutter/material.dart';

import '../../core/design/design.dart';

/// Semantic tone for [AppBadge].
///
/// Mirrors the agent web's booking-status mapping, which pairs Tailwind's
/// `-100` background with its `-700` foreground:
///
/// ```jsx
/// Completed → bg-green-100  text-green-700
/// Active    → bg-blue-100   text-blue-700
/// Cancelled → bg-red-100    text-red-700
/// Refund    → bg-purple-100 text-purple-700
/// default   → bg-amber-100  text-amber-700
/// ```
enum AppBadgeTone {
  /// Settled, completed, verified.
  success,

  /// In progress, active, upcoming.
  info,

  /// Cancelled, failed, rejected.
  danger,

  /// Refunds and reversals.
  special,

  /// Awaiting action — the web's fallback tone.
  pending,

  /// Non-semantic grey.
  neutral,
}

/// Pill-shaped status label.
///
/// Web: `inline-flex items-center px-2.5 py-1 rounded-full text-[12px] font-bold`
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
  });

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  Color get _background => switch (tone) {
    AppBadgeTone.success => AppColors.badgeGreenBg,
    AppBadgeTone.info => AppColors.badgeBlueBg,
    AppBadgeTone.danger => AppColors.badgeRedBg,
    AppBadgeTone.special => AppColors.badgePurpleBg,
    AppBadgeTone.pending => AppColors.badgeAmberBg,
    AppBadgeTone.neutral => AppColors.neutral100,
  };

  Color get _foreground => switch (tone) {
    AppBadgeTone.success => AppColors.badgeGreenFg,
    AppBadgeTone.info => AppColors.badgeBlueFg,
    AppBadgeTone.danger => AppColors.badgeRedFg,
    AppBadgeTone.special => AppColors.badgePurpleFg,
    AppBadgeTone.pending => AppColors.badgeAmberFg,
    AppBadgeTone.neutral => AppColors.textTertiary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: _foreground),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(label, style: AppText.badge.copyWith(color: _foreground)),
        ],
      ),
    );
  }
}
