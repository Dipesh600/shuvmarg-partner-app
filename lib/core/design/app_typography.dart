import 'package:flutter/material.dart';

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
/// Both faces are bundled — there is no runtime font fetching, which is what a
/// release build needs.
///
/// **Manrope** is one variable file whose `wght` axis spans 200–800. Critically
/// the axis *defaults to 200* (ExtraLight), so naming a weight via
/// [TextStyle.fontWeight] alone is not enough — Flutter would match the single
/// declared asset and render the entire scale ExtraLight. [sans] therefore
/// always emits a matching `FontVariation` on `wght`. The file was converted
/// losslessly from the agent web's own
/// `public/fonts/Manrope-VariableFont_wght.woff2` (WOFF2 is only a compression
/// wrapper around the same sfnt), so these are the web's exact letterforms
/// rather than a lookalike.
///
/// **Neue Machina** ships as two static faces, 300 and 400, each declared
/// weight checked against that file's OS/2 `usWeightClass`. There is
/// deliberately no heavier instance — the web sets `h1`–`h3` at weight 300 and
/// the light letterforms are the whole point. Asking this family for more than
/// 400 will match the 400 face and leave the engine to synthesise the
/// difference; see [display].
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppFonts {
  /// `true` — the Neue Machina faces are bundled and declared in `pubspec.yaml`.
  ///
  /// Deliberately `final` rather than `const`: as a `const` the analyzer
  /// reports whichever branch of [display] is not taken as dead code.
  static final bool hasNeueMachina = true;

  static const String _sans = 'Manrope';
  static const String _neueMachina = 'Neue Machina';

  /// Bounds of Manrope's `wght` axis, read from the file's own `fvar` table.
  /// 200 is also the axis default, which is why [sans] never omits the
  /// variation.
  static const double _wghtMin = 200;
  static const double _wghtMax = 800;

  /// Body / UI face. Matches the web's `--font-sans`.
  ///
  /// Emits `fontVariations` *and* preserves [base]'s `fontWeight`: the variation
  /// is what actually renders the weight, while `fontWeight` is kept so weight-
  /// aware widgets and `TextStyle.lerp` continue to behave sensibly.
  static TextStyle sans([TextStyle? base]) {
    final style = base ?? const TextStyle();
    final weight = style.fontWeight ?? FontWeight.w400;
    return style.copyWith(
      fontFamily: _sans,
      fontVariations: [FontVariation('wght', _wght(weight))],
    );
  }

  /// Display / heading face. Matches the web's `--font-display`.
  ///
  /// Falls back to [sans] — a bundled face — rather than to anything fetched at
  /// runtime, so text never depends on the network to render.
  static TextStyle display([TextStyle? base]) {
    if (hasNeueMachina) {
      return (base ?? const TextStyle()).copyWith(fontFamily: _neueMachina);
    }
    return sans(base);
  }

  /// Clamps a [FontWeight] onto Manrope's available axis range. Coordinates
  /// outside `fvar`'s min/max are undefined per the OpenType spec; Skia clamps
  /// them anyway, but doing it here keeps the emitted variation honest.
  static double _wght(FontWeight weight) =>
      weight.value.toDouble().clamp(_wghtMin, _wghtMax);
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
