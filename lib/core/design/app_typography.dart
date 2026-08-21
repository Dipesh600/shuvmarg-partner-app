import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — Typography
///
/// The agent web runs a two-font system:
///
///   • **Manrope**       → all UI/body text (`--font-sans`)
///   • **Neue Machina**  → all headings, weight 300, line-height 1.1,
///                          letter-spacing -0.01em (`--font-display`)
///
/// ⚠️ NEUE MACHINA IS NOT WIRED UP YET.
///
/// The web ships it as `.woff2` (`shuvmarg_partner_web/public/fonts/`), a
/// format Flutter cannot load — Flutter needs `.otf` or `.ttf`. Until those
/// files exist, [display] falls back to Manrope at weight 300 with Neue
/// Machina's metrics (tight line-height, negative tracking) so the *rhythm* of
/// the web's headings is preserved even though the letterforms differ.
///
/// To switch it on:
///   1. drop `NeueMachina-Regular.otf` + `NeueMachina-Light.otf` into
///      `assets/fonts/`
///   2. declare the family as `Neue Machina` in `pubspec.yaml`
///   3. flip [hasNeueMachina] to `true`
///
/// Nothing else in the codebase needs to change.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppFonts {
  /// Flip to `true` once the Neue Machina `.otf` files are bundled.
  /// See the class doc above for the three-step checklist.
  ///
  /// Deliberately `final` rather than `const`: as a `const false` the analyzer
  /// reports the enabled branch of [display] as dead code.
  static final bool hasNeueMachina = false;

  static const String _neueMachina = 'Neue Machina';

  /// Body / UI face. Matches the web's `--font-sans`.
  ///
  /// NOTE: `google_fonts` fetches at runtime on first launch and caches. For a
  /// production release Manrope should be bundled into `assets/fonts/` and
  /// `GoogleFonts.config.allowRuntimeFetching` set to `false`, so first launch
  /// and offline use don't silently fall back to a system face.
  static TextStyle sans([TextStyle? base]) => GoogleFonts.manrope(
    textStyle: base,
  );

  /// Display / heading face. Matches the web's `--font-display`.
  static TextStyle display([TextStyle? base]) {
    if (hasNeueMachina) {
      return (base ?? const TextStyle()).copyWith(fontFamily: _neueMachina);
    }
    return GoogleFonts.manrope(textStyle: base);
  }
}

/// The type scale.
///
/// Sizes are transcribed from the agent web, which specifies type in exact
/// pixel values (`text-[14px]`, `text-[11px]`, …) rather than a t-shirt scale.
/// Display sizes are stepped down from the web's desktop figures to suit a
/// handset viewport.
abstract final class AppText {
  // ───────────────────────────────────────────────────────────────────────────
  // Display — Neue Machina role
  //
  // Web: `h1, h2, h3 { font-weight: 300; line-height: 1.1;
  //                    letter-spacing: -0.01em; }`
  // Light weight at large sizes is what makes the web feel editorial; resist
  // bolding these.
  // ───────────────────────────────────────────────────────────────────────────
  static TextStyle get display1 => AppFonts.display(
    const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w300,
      height: 1.1,
      letterSpacing: -0.32, // -0.01em at 32px
      color: AppColors.textPrimary,
    ),
  );

  static TextStyle get display2 => AppFonts.display(
    const TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w300,
      height: 1.1,
      letterSpacing: -0.26,
      color: AppColors.textPrimary,
    ),
  );

  static TextStyle get display3 => AppFonts.display(
    const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w300,
      height: 1.15,
      letterSpacing: -0.22,
      color: AppColors.textPrimary,
    ),
  );

  // ───────────────────────────────────────────────────────────────────────────
  // Titles — Manrope, semibold. Section headers inside cards.
  // ───────────────────────────────────────────────────────────────────────────
  static TextStyle get titleLg => AppFonts.sans(
    const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.textPrimary,
    ),
  );

  static TextStyle get titleMd => AppFonts.sans(
    const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.textPrimary,
    ),
  );

  // ───────────────────────────────────────────────────────────────────────────
  // Body — web `body { font-size: 16px; line-height: 1.6; }`
  // ───────────────────────────────────────────────────────────────────────────
  static TextStyle get body => AppFonts.sans(
    const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: AppColors.textPrimary,
    ),
  );

  /// The workhorse size — web uses 14px for nearly all UI text.
  static TextStyle get bodyMd => AppFonts.sans(
    const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textPrimary,
    ),
  );

  static TextStyle get bodySm => AppFonts.sans(
    const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textSecondary,
    ),
  );

  // ───────────────────────────────────────────────────────────────────────────
  // Functional styles
  // ───────────────────────────────────────────────────────────────────────────

  /// Web `.form-label` — 13px / 600 / #444444.
  static TextStyle get label => AppFonts.sans(
    const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.textSecondary,
    ),
  );

  /// Web `.btn-primary` — 14px / 600 / letter-spacing 0.01em.
  static TextStyle get button => AppFonts.sans(
    const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.14,
    ),
  );

  /// Web `.eyebrow` — 11px / 700 / 0.12em / uppercase / brand-coloured.
  /// Apply `TextTransform`-equivalent by uppercasing the string at the callsite.
  static TextStyle get eyebrow => AppFonts.sans(
    const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 1.32, // 0.12em at 11px
      color: AppColors.primary,
    ),
  );

  /// Status pill text — web 12px / 700.
  static TextStyle get badge => AppFonts.sans(
    const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
  );

  /// Table column header — web 12px / 700 / uppercase / `tracking-wider`.
  static TextStyle get tableHead => AppFonts.sans(
    const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.6,
      color: AppColors.textMuted,
    ),
  );

  static TextStyle get caption => AppFonts.sans(
    const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.3,
      color: AppColors.textMuted,
    ),
  );

  /// Big KPI figures. The web sets stat numbers in `font-black`, which is the
  /// one place it deliberately breaks from the light display weight.
  static TextStyle get statNumber => AppFonts.sans(
    const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: -0.5,
      color: AppColors.textPrimary,
    ),
  );

  static TextStyle get statNumberSm => AppFonts.sans(
    const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: -0.3,
      color: AppColors.textPrimary,
    ),
  );

  /// Nav item caption on the floating bottom bar.
  static TextStyle get navLabel => AppFonts.sans(
    const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.1,
    ),
  );
}
