import 'package:flutter/material.dart';

/// Centralized Accessible Color Palette for the Accessibility Super App.
/// Core principles:
/// 1. Adheres strictly to WCAG 2.2 AA (minimum 4.5:1 ratio) and AAA (7:1 ratio) guidelines.
/// 2. Avoids single-point-of-failure colors (e.g. conveying critical info via red/green alone).
/// 3. Provides dedicated high-contrast themes for low-vision users.
class AppColors {
  AppColors._();

  // --- Light Theme Colors ---
  static const Color lightBackground = Color(0xFFFCFCFF);
  static const Color lightSurface = Color(0xFFF1F0F7);
  static const Color lightPrimary = Color(0xFF1E2F97); // Premium dark blue for high contrast
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFF4C5AAB);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F1016);
  static const Color lightTextSecondary = Color(0xFF434654);
  static const Color lightError = Color(0xFFBA1A1A); // Readable dark red
  static const Color lightOnError = Color(0xFFFFFFFF);

  // --- Dark Theme Colors ---
  static const Color darkBackground = Color(0xFF0F1016);
  static const Color darkSurface = Color(0xFF1B1B22);
  static const Color darkPrimary = Color(0xFFBCC2FF); // Soft, readable light blue
  static const Color darkOnPrimary = Color(0xFF001066);
  static const Color darkSecondary = Color(0xFF9EA7FC);
  static const Color darkOnSecondary = Color(0xFF0F1B6C);
  static const Color darkTextPrimary = Color(0xFFE2E1EC);
  static const Color darkTextSecondary = Color(0xFFA5A7B8);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);

  // --- High Contrast (Accessibility-First Mode) Colors ---
  // Designed specifically for users with severe low vision or color-blindness (7:1+ ratio).
  static const Color hcBackground = Color(0xFF000000);
  static const Color hcSurface = Color(0xFF121212);
  static const Color hcPrimary = Color(0xFFFFEA00); // Fully saturated accessibility yellow
  static const Color hcOnPrimary = Color(0xFF000000);
  static const Color hcSecondary = Color(0xFFFFFFFF);
  static const Color hcOnSecondary = Color(0xFF000000);
  static const Color hcTextPrimary = Color(0xFFFFFFFF);
  static const Color hcTextSecondary = Color(0xFFFFEA00);
  static const Color hcError = Color(0xFFFF2E2E);
  static const Color hcOnError = Color(0xFFFFFFFF);
}
