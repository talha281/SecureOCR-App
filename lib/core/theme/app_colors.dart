import 'package:flutter/material.dart';

/// SecureCode OCR — Color Palette
/// Premium dark-first design system
class AppColors {
  AppColors._();

  // ── Dark surface hierarchy ──────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0D0F14);
  static const Color surfaceDark = Color(0xFF131720);
  static const Color cardDark = Color(0xFF1A1F2E);
  static const Color elevatedDark = Color(0xFF222840);

  // ── Light surface hierarchy ─────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F6FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF0F2F8);
  static const Color elevatedLight = Color(0xFFE8EBF5);

  // ── Brand / Accent ──────────────────────────────────────────────────────
  /// Cyan-blue — primary action, interactive elements
  static const Color accent = Color(0xFF00D4FF);
  static const Color accentDim = Color(0xFF0099BB);
  static const Color accentGlow = Color(0x3300D4FF);

  /// Purple — code / syntax accent
  static const Color codePurple = Color(0xFF7C3AED);
  static const Color codePurpleDim = Color(0xFF5B21B6);

  /// Green — success, confidence
  static const Color success = Color(0xFF10B981);
  static const Color successGlow = Color(0x3310B981);

  /// Amber — warning, low-confidence highlight
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningGlow = Color(0x33F59E0B);

  /// Red — error, critical
  static const Color error = Color(0xFFEF4444);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF475569);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // ── Border / Divider ────────────────────────────────────────────────────
  static const Color borderDark = Color(0xFF2D3748);
  static const Color borderLight = Color(0xFFE2E8F0);

  // ── Gradient definitions ─────────────────────────────────────────────────
  static const LinearGradient heroGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D0F14), Color(0xFF131720), Color(0xFF0D1428)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4FF), Color(0xFF7C3AED)],
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1F2E), Color(0xFF1E2438)],
  );
}
