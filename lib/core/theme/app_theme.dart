import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppTheme {
  AppTheme._();

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.white,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.grey50,
    );

    return base.copyWith(
      cardColor: AppColors.white,
      textTheme: _textTheme(base.textTheme, AppColors.grey900),
      appBarTheme: _appBarTheme(AppColors.white, AppColors.grey900),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(
        border: AppColors.grey300,
        fill: AppColors.white,
        label: AppColors.grey500,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          side: const BorderSide(color: AppColors.grey200),
        ),
        color: AppColors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primary.withOpacity(0.08),
        labelStyle: GoogleFonts.inter(
          fontSize: AppSizes.textSm,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey400,
        backgroundColor: AppColors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.grey100,
        thickness: 1,
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: AppColors.accentLight,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
    );

    return base.copyWith(
      cardColor: AppColors.darkCard,
      textTheme: _textTheme(base.textTheme, AppColors.darkText),
      appBarTheme: _appBarTheme(AppColors.darkSurface, AppColors.darkText),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(dark: true),
      inputDecorationTheme: _inputDecorationTheme(
        border: AppColors.darkBorder,
        fill: AppColors.darkCard,
        label: AppColors.darkSubtext,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        color: AppColors.darkCard,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.darkSubtext,
        backgroundColor: AppColors.darkSurface,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static TextTheme _textTheme(TextTheme base, Color textColor) {
    final inter = GoogleFonts.interTextTheme(base);
    return inter.copyWith(
      displayLarge:   inter.displayLarge?.copyWith(color: textColor, fontWeight: FontWeight.w800),
      displayMedium:  inter.displayMedium?.copyWith(color: textColor, fontWeight: FontWeight.w700),
      headlineLarge:  inter.headlineLarge?.copyWith(color: textColor, fontWeight: FontWeight.w700),
      headlineMedium: inter.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      headlineSmall:  inter.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      titleLarge:     inter.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      titleMedium:    inter.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.w500),
      bodyLarge:      inter.bodyLarge?.copyWith(color: textColor),
      bodyMedium:     inter.bodyMedium?.copyWith(color: textColor),
      bodySmall:      inter.bodySmall?.copyWith(color: textColor.withOpacity(0.7)),
      labelLarge:     inter.labelLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600),
    );
  }

  static AppBarTheme _appBarTheme(Color bg, Color fg) => AppBarTheme(
    backgroundColor: bg,
    foregroundColor: fg,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.inter(
      fontSize: AppSizes.textXl,
      fontWeight: FontWeight.w700,
      color: fg,
    ),
    iconTheme: IconThemeData(color: fg, size: AppSizes.iconLg),
  );

  static ElevatedButtonThemeData _elevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: AppSizes.textLg,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme({bool dark = false}) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? AppColors.primaryLight : AppColors.primary,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
          side: BorderSide(
            color: dark ? AppColors.primaryLight : AppColors.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: AppSizes.textLg,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme({
    required Color border,
    required Color fill,
    required Color label,
  }) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        hintStyle: GoogleFonts.inter(fontSize: AppSizes.textMd, color: label),
        labelStyle: GoogleFonts.inter(fontSize: AppSizes.textMd, color: label),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      );
}
