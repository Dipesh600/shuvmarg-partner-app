
import 'package:flutter/material.dart';

import '../../core/design/design.dart';

/// Layout orientation for the Shuvmarg brand logo.
enum AppLogoVariant {
  horizontal,
  stacked,
  symbolOnly,
  wordmarkOnly,
}

/// The official Shuvmarg Partner brand logo component.
///
/// Implements the brand design rules:
/// - Symbol: Two slanted rounded road stripes from `logo_orange.webp`.
/// - Typography: **Shuv** (Dark / Reversed White) + **Marg** (Brand Orange / Reversed White).
/// - Optional `PARTNER` badge capsule and tagline.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.variant = AppLogoVariant.horizontal,
    this.showTagline = false,
    this.showPartnerBadge = false,
    this.isReversed = false,
    this.iconSize = 36,
    this.fontSize = 24,
    this.taglineText = 'Your Journey, Our Commitment.',
  });

  /// Layout variant (horizontal lockup, stacked, or individual pieces).
  final AppLogoVariant variant;

  /// Whether to render the brand commitment tagline.
  final bool showTagline;

  /// Whether to include the pill-shaped `PARTNER` badge.
  final bool showPartnerBadge;

  /// If `true`, paints all text and icon strokes in white for dark or orange backgrounds.
  final bool isReversed;

  /// Height/width of the logo symbol icon.
  final double iconSize;

  /// Base font size for the "ShuvMarg" wordmark.
  final double fontSize;

  /// Tagline text to display when [showTagline] is enabled.
  final String taglineText;

  @override
  Widget build(BuildContext context) {
    if (variant == AppLogoVariant.symbolOnly) {
      return _buildSymbol();
    }

    if (variant == AppLogoVariant.wordmarkOnly) {
      return _buildWordmarkWithBadges();
    }

    if (variant == AppLogoVariant.stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSymbol(),
          SizedBox(height: iconSize * 0.3),
          _buildWordmarkWithBadges(),
          if (showTagline) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildTagline(),
          ],
        ],
      );
    }

    // Default horizontal lockup
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSymbol(),
            SizedBox(width: iconSize * 0.35),
            _buildWordmarkWithBadges(),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: iconSize * 1.35),
            child: _buildTagline(),
          ),
        ],
      ],
    );
  }

  Widget _buildSymbol() {
    return Image.asset(
      'assets/images/logo_orange.webp',
      height: iconSize,
      fit: BoxFit.contain,
      color: isReversed ? AppColors.white : null,
      colorBlendMode: isReversed ? BlendMode.srcIn : null,
    );
  }

  Widget _buildWordmarkWithBadges() {
    final shuvColor = isReversed ? AppColors.white : AppColors.neutral900;
    final margColor = isReversed ? AppColors.white : AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Shuv',
                style: TextStyle(
                  fontFamily: 'Neue Machina',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: shuvColor,
                  letterSpacing: -0.4,
                ),
              ),
              TextSpan(
                text: 'Marg',
                style: TextStyle(
                  fontFamily: 'Neue Machina',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: margColor,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        if (showPartnerBadge) ...[
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isReversed
                  ? AppColors.white.withValues(alpha: 0.2)
                  : AppColors.primary,
              borderRadius: AppRadius.pillRadius,
              border: isReversed
                  ? Border.all(color: AppColors.white, width: 1)
                  : null,
            ),
            child: Text(
              'PARTNER',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: (fontSize * 0.4).clamp(9.0, 12.0),
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTagline() {
    return Text(
      '— $taglineText —',
      style: AppText.caption.copyWith(
        color: isReversed
            ? AppColors.white.withValues(alpha: 0.8)
            : AppColors.textTertiary,
        fontSize: (fontSize * 0.42).clamp(10.0, 13.0),
        letterSpacing: 0.2,
      ),
    );
  }
}
