import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — Colour Tokens
///
/// Ported 1:1 from the agent web's design system
/// (`shuvmarg_partner_web/src/app/globals.css` → "Shuv Marg Design System —
/// Design Constitution v1"), with one deliberate substitution:
///
///   the web's two brand reds are replaced by the Shuvmarg brand orange.
///
///   web `--color-maroon` #7A1D1B  ─┐
///   web coral (untokenised) #D96B62 ┴─→  [AppColors.primary] #D94328
///
/// #D94328 is not a new invention: it is the vermillion already used ~210× in
/// `shuvmarg_passenger_website`, and matches the app icon. Adopting it here
/// aligns the mobile app with the rest of the platform instead of introducing
/// yet another brand red.
///
/// RULE (production_project_rules.md §4.1): no hardcoded hex colours anywhere
/// else in the codebase. Every colour the app uses must be declared in this
/// file and referenced through it.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppColors {
  // ───────────────────────────────────────────────────────────────────────────
  // Brand — Orange scale
  //
  // Derived around the #D94328 brand mid-tone. `primary` is the only value the
  // brand guideline fixes; the rest of the ramp exists so states (hover,
  // pressed, tints, disabled) never need an ad-hoc opacity hack.
  // ───────────────────────────────────────────────────────────────────────────
  static const Color orange50 = Color(0xFFFEF4F1);
  static const Color orange100 = Color(0xFFFCE3DC);
  static const Color orange200 = Color(0xFFF8C4B6);
  static const Color orange300 = Color(0xFFF09E88);
  static const Color orange400 = Color(0xFFE4714F);
  static const Color orange500 = Color(0xFFD94328); // ← brand
  static const Color orange600 = Color(0xFFBE3520);
  static const Color orange700 = Color(0xFF9C2A19);
  static const Color orange800 = Color(0xFF7A2113);
  static const Color orange900 = Color(0xFF55170D);

  /// The brand colour. Primary CTAs, focus rings, active nav, eyebrow labels.
  /// Replaces web `--color-maroon` (#7A1D1B).
  static const Color primary = orange500;

  /// Pressed / hover fill for primary surfaces.
  /// Replaces web `--color-maroon-dark` (#5C1414).
  static const Color primaryDark = orange600;

  /// Light brand tint — subtle fills, selected-but-quiet states.
  /// Replaces web `--color-maroon-light` (#F0A09B).
  static const Color primaryLight = orange300;

  /// Faintest brand wash — used behind icons and step chips.
  static const Color primarySurface = orange50;

  /// Brand colour rendered on top of a dark/brand fill.
  static const Color onPrimary = white;

  // ───────────────────────────────────────────────────────────────────────────
  // Accent — Gold
  //
  // Carried over unchanged from the web, where gold marks the "+" / "%"
  // deltas on stat figures and the greeting name. It is an accent only —
  // never a CTA.
  // ───────────────────────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFC99A4A);
  static const Color goldLight = Color(0xFFEBC77F);

  // ───────────────────────────────────────────────────────────────────────────
  // Surfaces
  //
  // The web is a *warm light* product, not a dark one. Backgrounds are creams,
  // never pure white, and card borders are warm beige rather than grey — that
  // warmth is the most recognisable part of the visual language.
  // ───────────────────────────────────────────────────────────────────────────

  /// Primary app canvas. Web workspace/dashboard background (#FAF7F2).
  static const Color canvas = Color(0xFFFAF7F2);

  /// Marketing / onboarding canvas. Web `body` background (#FDFAF6).
  static const Color canvasAlt = Color(0xFFFDFAF6);

  /// Auth-screen canvas. Web login outer background (#FFFCF8).
  static const Color canvasAuth = Color(0xFFFFFCF8);

  /// Card and sheet fill. Always pure white against the cream canvas.
  static const Color surface = white;

  /// Ivory panel fill — used for inset/quiet regions inside white cards.
  static const Color ivory = Color(0xFFF8F1E3);
  static const Color ivoryDark = Color(0xFFEDE5D8);

  /// Warm card border (web #E8E0D4) and its pressed/hover state (#D0C8BC).
  /// Deliberately *not* a neutral grey.
  static const Color border = Color(0xFFE8E0D4);
  static const Color borderStrong = Color(0xFFD0C8BC);

  /// Input border at rest. Web `.form-input` uses a cooler grey here (#DDDDDD)
  /// than the card border, so both are kept distinct.
  static const Color borderInput = neutral200;

  // ───────────────────────────────────────────────────────────────────────────
  // Neutrals — web `@theme` neutral ramp, verbatim
  // ───────────────────────────────────────────────────────────────────────────
  static const Color neutral900 = Color(0xFF111111);
  static const Color neutral800 = Color(0xFF222222);
  static const Color neutral700 = Color(0xFF444444);
  static const Color neutral600 = Color(0xFF666666);
  static const Color neutral500 = Color(0xFF888888);
  static const Color neutral400 = Color(0xFFAAAAAA);
  static const Color neutral300 = Color(0xFFCCCCCC);
  static const Color neutral200 = Color(0xFFDDDDDD);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);

  // ───────────────────────────────────────────────────────────────────────────
  // Text
  //
  // No pure black — the web tops out at #111111.
  // ───────────────────────────────────────────────────────────────────────────
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral700;
  static const Color textTertiary = neutral600;
  static const Color textMuted = neutral500;
  static const Color textPlaceholder = neutral400;
  static const Color textOnPrimary = white;

  // ───────────────────────────────────────────────────────────────────────────
  // Semantic — web `@theme` semantic tokens
  // ───────────────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFD32F2F);

  /// Pressed state for a danger-filled surface.
  static const Color dangerDark = Color(0xFFB3251F);

  /// Rose wash behind destructive rows on press. Web #FFF4F3.
  static const Color dangerSurface = Color(0xFFFFF4F3);

  // ───────────────────────────────────────────────────────────────────────────
  // Status badge pairs
  //
  // The web uses Tailwind's `-100`/`-700` pastel pairs for booking status
  // pills. Tailwind isn't available in Flutter, so the exact values are
  // transcribed here.
  // ───────────────────────────────────────────────────────────────────────────
  static const Color badgeGreenBg = Color(0xFFDCFCE7);
  static const Color badgeGreenFg = Color(0xFF15803D);
  static const Color badgeBlueBg = Color(0xFFDBEAFE);
  static const Color badgeBlueFg = Color(0xFF1D4ED8);
  static const Color badgeRedBg = Color(0xFFFEE2E2);
  static const Color badgeRedFg = Color(0xFFB91C1C);
  static const Color badgePurpleBg = Color(0xFFF3E8FF);
  static const Color badgePurpleFg = Color(0xFF7E22CE);
  static const Color badgeAmberBg = Color(0xFFFEF3C7);
  static const Color badgeAmberFg = Color(0xFFB45309);

  // ───────────────────────────────────────────────────────────────────────────
  // Derived / translucent
  //
  // Pre-computed so call sites never sprinkle `.withValues(alpha: ...)` on a
  // brand colour and quietly drift out of spec.
  // ───────────────────────────────────────────────────────────────────────────

  /// Focus ring around a focused input. Web: `rgba(122,29,27,0.10)` → brand.
  static const Color focusRing = Color(0x1AD94328); // 10%

  /// Danger focus ring. Web: `rgba(211,47,47,0.10)`.
  static const Color focusRingDanger = Color(0x1AD32F2F); // 10%

  /// Fill behind a pressed secondary (outlined) button. Web: 6% maroon.
  static const Color primaryPressed = Color(0x0FD94328); // 6%

  /// Fill behind a pressed ghost button. Web: 5% black.
  static const Color ghostPressed = Color(0x0D000000); // 5%

  /// Inactive nav item on a brand-filled bar. Web: `text-white/80`.
  static const Color navInactive = Color(0xCCFFFFFF); // 80%

  /// Hover wash on a brand-filled bar. Web: `hover:bg-white/20`.
  static const Color navHover = Color(0x33FFFFFF); // 20%

  // ───────────────────────────────────────────────────────────────────────────
  // Shadow tints
  //
  // `const BoxShadow` requires a const colour, so "primary at 30% opacity"
  // cannot be computed at the call site. These live here rather than in
  // AppShadows so this file stays the only place hex appears (§4.1).
  // ───────────────────────────────────────────────────────────────────────────

  /// Resting card. Web: `rgba(0,0,0,0.04)`.
  static const Color shadowSoft = Color(0x0A000000); // 4%

  /// Raised surface. Web: `rgba(0,0,0,0.08)`.
  static const Color shadowMedium = Color(0x14000000); // 8%

  /// Dropdowns and popovers. Web: `rgba(0,0,0,0.12)`.
  static const Color shadowStrong = Color(0x1F000000); // 12%

  /// Modals and bottom sheets. Web: `rgba(0,0,0,0.16)`.
  static const Color shadowModal = Color(0x29000000); // 16%

  /// The ambient coloured glow under brand-filled surfaces (primary buttons,
  /// floating nav). Web used `rgba(122,29,27,0.30)` / `rgba(217,107,98,0.3)`;
  /// re-tinted to the brand orange.
  static const Color shadowBrand = Color(0x4DD94328); // 30%
}
