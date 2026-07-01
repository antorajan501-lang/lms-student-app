import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const primary        = Color(0xFFFF6F06); // Orange primary
  static const primaryLight   = Color(0xFFFF8E3C);
  static const primaryDark    = Color(0xFFE05600);
  static const accent         = Color(0xFF1D4ED8); // Blue secondary
  static const accentLight    = Color(0xFF3B82F6);

  // ── Neutrals ──────────────────────────────────────────────────────────────
  static const white          = Color(0xFFFFFFFF);
  static const black          = Color(0xFF0A0A0A);
  static const grey50         = Color(0xFFF9FAFB);
  static const grey100        = Color(0xFFF3F4F6);
  static const grey200        = Color(0xFFE5E7EB);
  static const grey300        = Color(0xFFD1D5DB);
  static const grey400        = Color(0xFF9CA3AF);
  static const grey500        = Color(0xFF6B7280);
  static const grey600        = Color(0xFF4B5563);
  static const grey700        = Color(0xFF374151);
  static const grey800        = Color(0xFF1F2937);
  static const grey900        = Color(0xFF111827);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const success        = Color(0xFF10B981);
  static const successLight   = Color(0xFFD1FAE5);
  static const warning        = Color(0xFFF59E0B);
  static const warningLight   = Color(0xFFFEF3C7);
  static const error          = Color(0xFFEF4444);
  static const errorLight     = Color(0xFFFEE2E2);
  static const info           = Color(0xFF06B6D4);
  static const infoLight      = Color(0xFFCFFAFE);

  // ── Surface (dark mode) ───────────────────────────────────────────────────
  static const darkBg         = Color(0xFF0F172A);
  static const darkSurface    = Color(0xFF1E293B);
  static const darkCard       = Color(0xFF334155);
  static const darkBorder     = Color(0xFF475569);
  static const darkText       = Color(0xFFF1F5F9);
  static const darkSubtext    = Color(0xFF94A3B8);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientAccent = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientDark = LinearGradient(
    colors: [darkBg, darkSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
