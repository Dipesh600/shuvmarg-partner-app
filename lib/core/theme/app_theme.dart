import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHUVMARG DESIGN TOKENS
// Source: mobile-app-ui-color-guide.md + 02-screen-specs.md
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Background & Surface ────────────────────────────────────────────────
  static const Color bgBase       = Color(0xFF0A1F1C); // AMOLED near-black
  static const Color bgCard       = Color(0x16003D38); // 88% #00564E
  static const Color bgSurface    = Color(0xFF0F2926); // elevated surface
  static const Color bgInput      = Color(0x0AFFFFFF); // 4% white tint

  // ── Brand Primary ───────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF00564E); // spec §27
  static const Color primaryDark  = Color(0xFF003D38);
  static const Color secondary    = Color(0xFF568C82);

  // ── Accent ──────────────────────────────────────────────────────────────
  static const Color accentLime   = Color(0xFFD3D925); // CTA accent
  static const Color accentGold   = Color(0xFFD9CD25);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary  = Color(0xFFF5F7F6);
  static const Color textSecond   = Color(0xFFB7C7C3);
  static const Color textAccent   = Color(0xFFD3D925);

  // ── Screen-spec colors (from 02-screen-specs.md) ────────────────────────
  // Used for legacy passenger app / agent app compatibility
  static const Color specPrimary  = Color(0xFF1F5D4F); // spec header color
  static const Color specCta      = Color(0xFFD64545); // spec red CTA
  static const Color specSurface  = Color(0xFFF5F5F5);
  static const Color specSubtext  = Color(0xFF6B6B6B);
  static const Color specText     = Color(0xFF1A1A1A);

  // ── Status / Semantic ───────────────────────────────────────────────────
  static const Color success      = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFE1F5EE);
  static const Color warning      = Color(0xFFEF9F27); // CASH badge amber
  static const Color warningLight = Color(0xFFFAEEDA);
  static const Color error        = Color(0xFFEF4444);
  static const Color errorLight   = Color(0xFFFFEEEE);

  // ── Stroke / Border ─────────────────────────────────────────────────────
  static const Color stroke       = Color(0x14FFFFFF); // 8% white

  // ── Nav icons ───────────────────────────────────────────────────────────
  static const Color navActive    = Color(0xFFD3D925);
  static const Color navInactive  = Color(0x73FFFFFF); // 45% white

  // Booking badge colors
  static const Color badgeOnlineBg   = Color(0xFF1F5D4F);
  static const Color badgeCashBg     = Color(0xFFEF9F27);
  static const Color badgeOnlineText = Color(0xFFFFFFFF);
  static const Color badgeCashText   = Color(0xFFFFFFFF);
}

// ─────────────────────────────────────────────────────────────────────────────
// TEXT STYLES  (Inter via google_fonts)
// Weights: 400=Regular 500=Medium 600=SemiBold 700=Bold
// Sizes from §5 of color guide
// ─────────────────────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _inter(double size, FontWeight weight, Color color) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

  // Headings
  static TextStyle heading1(Color c)   => _inter(24, FontWeight.w700, c);
  static TextStyle heading2(Color c)   => _inter(20, FontWeight.w600, c);
  static TextStyle heading3(Color c)   => _inter(18, FontWeight.w600, c);

  // Body
  static TextStyle bodyLarge(Color c)  => _inter(16, FontWeight.w400, c);
  static TextStyle bodyMed(Color c)    => _inter(14, FontWeight.w400, c);
  static TextStyle bodySmall(Color c)  => _inter(12, FontWeight.w400, c);
  static TextStyle bodyTiny(Color c)   => _inter(10, FontWeight.w500, c);

  // Semibold variants
  static TextStyle labelLg(Color c)    => _inter(16, FontWeight.w600, c);
  static TextStyle labelMed(Color c)   => _inter(14, FontWeight.w600, c);
  static TextStyle labelSm(Color c)    => _inter(12, FontWeight.w500, c);

  // Hero numbers (commission display, etc.)
  static TextStyle heroNum(Color c)    => _inter(32, FontWeight.w700, c);
  static TextStyle heroNumSm(Color c)  => _inter(24, FontWeight.w700, c);

  // Button text
  static TextStyle button(Color c)     => _inter(16, FontWeight.w600, c);
  static TextStyle buttonSm(Color c)   => _inter(14, FontWeight.w600, c);
}

// ─────────────────────────────────────────────────────────────────────────────
// SPACING / RADIUS / SHADOWS
// Base unit: 4px (§13 of color guide)
// ─────────────────────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class AppRadius {
  AppRadius._();
  static const double card    = 24;  // §14
  static const double input   = 18;
  static const double button  = 16;
  static const double nav     = 32;
  static const double badge   = 6;
  static const double full    = 999;
}

class AppShadows {
  AppShadows._();

  // Colored ambient shadow (§15 — no black shadows)
  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.25),
      blurRadius: 40,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> glow = [
    BoxShadow(
      color: AppColors.accentLime.withOpacity(0.30),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Colors.black.withOpacity(0.40),
      blurRadius: 24,
      offset: const Offset(0, -4),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD DECORATION  (§8 of color guide)
// ─────────────────────────────────────────────────────────────────────────────
BoxDecoration get appCardDecoration => BoxDecoration(
  color: const Color(0xE100564E), // rgba(0,86,78,0.88)
  border: Border.all(color: AppColors.stroke),
  borderRadius: BorderRadius.circular(AppRadius.card),
  boxShadow: AppShadows.card,
);

BoxDecoration get appInputDecoration => BoxDecoration(
  color: AppColors.bgInput,
  border: Border.all(color: AppColors.stroke),
  borderRadius: BorderRadius.circular(AppRadius.input),
);

// ─────────────────────────────────────────────────────────────────────────────
// MATERIAL THEME
// ─────────────────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.bgSurface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.bgBase,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),

    // ── Cursor & text selection ────────────────────────────────────────────
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.textPrimary,           // white blinking cursor
      selectionColor: Color(0x4400564E),             // green tint selection
      selectionHandleColor: AppColors.accentLime,   // lime drag handles
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bgBase,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgInput,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: GoogleFonts.inter(
        color: AppColors.textSecond,
        fontSize: 14,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
