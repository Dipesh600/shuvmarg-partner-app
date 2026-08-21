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
/// Neue Machina is wired up: `NeueMachina-Light.otf` (weight 300) and
/// `NeueMachina-Regular.otf` (weight 400) are bundled under `assets/fonts/`
/// and declared as family `Neue Machina` in `pubspec.yaml`. Both files were
/// verified against their OS/2 `usWeightClass` before being declared.
///
/// ⚠️ MANROPE IS STILL FETCHED AT RUNTIME.
///
/// The `.otf` supplied for bundling is named `Manrope-VariableFont_wght.otf`
/// but is not a variable font: it carries no `fvar` table, has no axes, and
/// reports `usWeightClass` 200 — it is a single static Manrope ExtraLight.
/// Declaring it as family `Manrope` would collapse the whole w300–w800 scale
/// below onto ExtraLight, including the `font-black` KPI figures. So [sans]
/// deliberately stays on `google_fonts` until either the genuine variable
/// `Manrope[wght].ttf` or the individual static instances are supplied.
///
/// Until then `google_fonts` cannot be dropped from `pubspec.yaml`, and a cold
/// first launch with no network still falls back to a system face.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppFonts {
  /// `true` — the Neue Machina faces are bundled and declared.
  ///
  /// Deliberately `final` rather than `const`: as a `const` the analyzer
  /// reports whichever branch of [display] is not taken as dead code.
  static final bool hasNeueMachina = true;

  static const String _neueMachina = 'Neue Machina';

  /// Body / UI face. Matches the web's `--font-sans`.
  ///
  /// NOTE: runtime-fetched, not bundled — see the class doc for why. This is a
  /// release blocker, not a resting state: `google_fonts` fetches on first
  /// launch and caches, so an offline first run silently renders a system face
  /// instead of Manrope.
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
