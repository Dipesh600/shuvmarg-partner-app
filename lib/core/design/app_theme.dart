import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — ThemeData assembly
///
/// The agent web is a **warm light** product: cream canvas, white cards, warm
/// beige borders, near-black (never pure black) text. The previous mobile theme
/// was an AMOLED dark emerald/lime system inherited from the passenger app —
/// that is intentionally gone.
/// ─────────────────────────────────────────────────────────────────────────────

/// Status bar / nav bar styling for the light cream canvas.
///
/// Dark icons on a light surface — the inverse of the old dark theme.
const SystemUiOverlayStyle appSystemOverlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark, // Android
  statusBarBrightness: Brightness.light, // iOS
  systemNavigationBarColor: AppColors.canvas,
  systemNavigationBarIconBrightness: Brightness.dark,
);

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primarySurface,
    onPrimaryContainer: AppColors.orange800,
    secondary: AppColors.gold,
    onSecondary: AppColors.neutral900,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerLowest: AppColors.canvas,
    surfaceContainerLow: AppColors.canvasAlt,
    surfaceContainer: AppColors.ivory,
    error: AppColors.danger,
    onError: AppColors.white,
    outline: AppColors.border,
    outlineVariant: AppColors.borderStrong,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    canvasColor: AppColors.canvas,

    // Manrope everywhere by default; display styles opt in explicitly.
    textTheme: _textTheme,

    // ── App bar ───────────────────────────────────────────────────────────
    // Flat and transparent — the web has no filled app bar on mobile; the
    // brand header is a content element, not chrome.
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: appSystemOverlay,
      titleTextStyle: AppText.titleLg,
    ),

    // ── Inputs ────────────────────────────────────────────────────────────
    // Mirrors web `.form-input`: 48px tall, 12px radius, 1.5px border.
    // The 3px focus *ring* (a box-shadow on the web) can't be expressed in
    // InputDecoration, so `AppTextField` layers it on top.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      hintStyle: AppText.bodyMd.copyWith(color: AppColors.textPlaceholder),
      labelStyle: AppText.label,
      errorStyle: AppText.caption.copyWith(color: AppColors.danger),
      enabledBorder: _inputBorder(AppColors.borderInput),
      border: _inputBorder(AppColors.borderInput),
      focusedBorder: _inputBorder(AppColors.primary),
      disabledBorder: _inputBorder(AppColors.neutral100),
      errorBorder: _inputBorder(AppColors.danger),
      focusedErrorBorder: _inputBorder(AppColors.danger),
    ),

    // ── Buttons ───────────────────────────────────────────────────────────
    // `AppButton` is the intended API, but theming the Material buttons keeps
    // any stray ElevatedButton/TextButton on-brand rather than Material-purple.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        disabledForegroundColor: AppColors.white.withValues(alpha: 0.8),
        elevation: 0,
        minimumSize: const Size(0, AppSpacing.controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        textStyle: AppText.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, AppSpacing.controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        textStyle: AppText.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppText.button,
      ),
    ),

    // ── Surfaces ──────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.neutral200,
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTopRadius),
      showDragHandle: true,
      dragHandleColor: AppColors.neutral300,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      titleTextStyle: AppText.titleLg,
      contentTextStyle: AppText.bodyMd,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.neutral900,
      contentTextStyle: AppText.bodyMd.copyWith(color: AppColors.white),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),

    // ── Misc controls ─────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.neutral100,
      selectedColor: AppColors.primary,
      labelStyle: AppText.badge,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.orange100,
      circularTrackColor: AppColors.orange100,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.orange200,
      selectionHandleColor: AppColors.primary,
    ),
    splashFactory: InkSparkle.splashFactory,
    highlightColor: AppColors.primaryPressed,
    splashColor: AppColors.primaryPressed,
  );
}

InputBorder _inputBorder(Color color) => OutlineInputBorder(
  borderRadius: AppRadius.inputRadius,
  borderSide: BorderSide(color: color, width: 1.5),
);

/// Maps the design scale onto Material's slots so unstyled Material widgets
/// still land on-brand.
TextTheme get _textTheme => TextTheme(
  displayLarge: AppText.display1,
  displayMedium: AppText.display2,
  displaySmall: AppText.display3,
  headlineMedium: AppText.display3,
  headlineSmall: AppText.titleLg,
  titleLarge: AppText.titleLg,
  titleMedium: AppText.titleMd,
  titleSmall: AppText.label,
  bodyLarge: AppText.body,
  bodyMedium: AppText.bodyMd,
  bodySmall: AppText.bodySm,
  labelLarge: AppText.button,
  labelMedium: AppText.label,
  labelSmall: AppText.caption,
);
