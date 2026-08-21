import 'package:flutter/material.dart';

import '../../core/design/design.dart';

/// The standard white surface, ported from the agent web's card convention:
///
/// ```jsx
/// className="bg-white rounded-2xl p-5
///            shadow-[0_2px_12px_rgba(0,0,0,0.04)]
///            border border-neutral-100"
/// ```
///
/// The border is deliberately the *warm* beige `AppColors.border` rather than a
/// cool grey — against the cream canvas a grey border reads as dirty.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.margin,
    this.width,
  });

  final Widget child;

  /// Defaults to the web's `p-5` (20px) on all sides.
  final EdgeInsetsGeometry? padding;

  /// When non-null the card becomes tappable and its border darkens on press
  /// (web `.card:hover { border-color: #D0C8BC }`).
  final VoidCallback? onTap;

  final EdgeInsetsGeometry? margin;
  final double? width;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  bool get _interactive => widget.onTap != null;

  void _setPressed(bool value) {
    if (!_interactive) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: AppMotion.base,
      width: widget.width,
      margin: widget.margin,
      padding:
          widget.padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: _pressed ? AppColors.borderStrong : AppColors.border,
        ),
        boxShadow: AppShadows.card,
      ),
      child: widget.child,
    );

    if (!_interactive) return card;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: card,
    );
  }
}

/// A quiet inset region *inside* an [AppCard] — the web's ivory panel.
///
/// Use for sub-groupings (a fare breakdown, a read-only summary) where another
/// white-on-white card would create no separation.
class AppInsetPanel extends StatelessWidget {
  const AppInsetPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.inset,
      child: child,
    );
  }
}
