import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — Shape, spacing, elevation and motion tokens
///
/// Ported from the agent web's `@theme inline` block and the component
/// conventions observed across `shuvmarg_partner_web`.
/// ─────────────────────────────────────────────────────────────────────────────

/// Corner radii — the web declares an 8px-based ramp in `globals.css`.
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double pill = 999;

  // ── Component-level aliases ───────────────────────────────────────────────
  // Named so a widget never has to guess which step of the ramp it wants.

  /// Cards. Web dashboard cards are consistently `rounded-2xl`.
  static const double card = xl;

  /// Buttons. Web `.btn-primary` / `.btn-secondary` → 12px.
  static const double button = lg;

  /// Inputs. Web `.form-input` → 12px.
  static const double input = lg;

  /// Inset panels nested inside a card — one step tighter than the card itself.
  static const double panel = lg;

  /// The bottom nav bar itself. Web mobile nav → `rounded-2xl`.
  static const double navBar = xl;

  /// Large content sheets that overlap a brand header.
  /// Web mobile dashboard → `rounded-t-[32px]`.
  static const double sheet = 32;

  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get buttonRadius => BorderRadius.circular(button);
  static BorderRadius get inputRadius => BorderRadius.circular(input);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);

  /// Top-only radius for a sheet that sits over a brand header bleed.
  static const BorderRadius sheetTopRadius = BorderRadius.only(
    topLeft: Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );
}

/// Spacing — 4px base grid, matching the web's Tailwind spacing usage.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard screen gutter. Web mobile → `px-4`.
  static const double gutter = md;

  /// Interior padding of a card. Web dashboard cards → `p-5`.
  static const double cardPadding = lg;

  /// Fixed control height shared by buttons and inputs (web: 48px).
  static const double controlHeight = 48;

  /// Height of the floating bottom nav (web: `h-16`).
  static const double navHeight = 64;

  /// Vertical inset of the floating nav from the bottom edge (web: `bottom-6`).
  static const double navBottomInset = 24;

  /// Horizontal inset of the floating nav (web: `left-4 right-4`).
  static const double navSideInset = md;

  /// Total space the floating nav occupies, for scroll-view bottom padding.
  static const double navReservedSpace =
      navHeight + navBottomInset + md;
}

/// Elevation — the web never uses harsh black drop shadows. Everything is a
/// wide, very low-opacity ambient spread; brand surfaces get a *coloured*
/// shadow in the brand hue instead of grey.
abstract final class AppShadows {
  /// Resting card. Web `shadow-[0_2px_12px_rgba(0,0,0,0.04)]`.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadowSoft,
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  /// Raised surface, e.g. a search field. Web `shadow-[0_8px_30px_rgba(0,0,0,0.08)]`.
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ];

  /// Dropdowns and popovers. Web `shadow-[0_8px_30px_rgba(0,0,0,0.12)]`.
  static const List<BoxShadow> popover = [
    BoxShadow(
      color: AppColors.shadowStrong,
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ];

  /// Modal / bottom sheet. Web `shadow-[0_24px_64px_rgba(0,0,0,0.16)]`.
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: AppColors.shadowModal,
      blurRadius: 64,
      offset: Offset(0, 24),
    ),
  ];

  /// Primary button. Web `box-shadow: 0 4px 12px rgba(122,29,27,0.30)` →
  /// re-tinted to the brand orange.
  static const List<BoxShadow> brandButton = [
    BoxShadow(
      color: AppColors.shadowBrand,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Floating bottom nav glow. Web `shadow-[0_8px_32px_rgba(217,107,98,0.3)]`
  /// → re-tinted to the brand orange.
  static const List<BoxShadow> navGlow = [
    BoxShadow(
      color: AppColors.shadowBrand,
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];
}

/// Motion — the web is consistent about two curves and three durations.
abstract final class AppMotion {
  /// Dropdown / popover in-out. Web `transition={{ duration: 0.15 }}`.
  static const Duration fast = Duration(milliseconds: 150);

  /// Colour and border transitions. Web `transition: ... 0.2s ease`.
  static const Duration base = Duration(milliseconds: 200);

  /// Large morphing chrome. Web `duration-[450ms]`.
  static const Duration morph = Duration(milliseconds: 450);

  /// Content entrance. Web `.animate-fade-up` → 0.5s.
  static const Duration entrance = Duration(milliseconds: 500);

  /// Expo-out. Web `cubic-bezier(0.16, 1, 0.3, 1)` — the entrance easing used
  /// for every fade-up in the agent web.
  static const Curve expoOut = Cubic(0.16, 1, 0.3, 1);

  /// Web `cubic-bezier(0.2, 0.8, 0.2, 1)` — used for navbar morphing.
  static const Curve smooth = Cubic(0.2, 0.8, 0.2, 1);
}

/// Ready-made decorations for the two most repeated containers in the web app,
/// so screens don't rebuild them by hand and drift.
abstract final class AppDecorations {
  /// The standard white dashboard card: warm border, soft ambient shadow.
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.cardRadius,
    border: Border.all(color: AppColors.border),
    boxShadow: AppShadows.card,
  );

  /// A quiet inset region *inside* a white card (web ivory panels). One step
  /// tighter than a card, so a nested panel reads as subordinate.
  static BoxDecoration get inset => BoxDecoration(
    color: AppColors.ivory,
    borderRadius: BorderRadius.circular(AppRadius.panel),
  );

  /// The floating brand-filled bottom navigation bar.
  static BoxDecoration get navBar => BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(AppRadius.navBar),
    boxShadow: AppShadows.navGlow,
  );

  /// White content sheet that overlaps a brand header bleed.
  static BoxDecoration get sheet => const BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.sheetTopRadius,
  );
}
