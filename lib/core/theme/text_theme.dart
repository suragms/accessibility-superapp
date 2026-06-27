import 'package:flutter/material.dart';

/// Accessibility-First Text Theme System.
/// Key Features:
/// 1. Provides scaling-safe text configurations.
/// 2. Integrates a dyslexia-friendly font option (System Sans / Comic Neue / Dyslexic).
/// 3. Standardized weight classes avoiding ultra-thin weights (which are unreadable for low-vision users).
class AppTextTheme {
  AppTextTheme._();

  /// Standard font family setup.
  /// If [useDyslexicFont] is true, uses a legible, high-readability font structure.
  static TextTheme buildTextTheme({required bool useDyslexicFont}) {
    // We fall back to system fonts (Sans-Serif/Roboto/Arial) configured with letter-spacing
    // and heavier weights if dyslexic mode is active, or standard premium sans-serif.
    final String fontFamily = useDyslexicFont ? 'Comic Neue' : 'Outfit';

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w800, // Bold
        fontSize: 32.0,
        letterSpacing: useDyslexicFont ? 0.5 : 0.0,
        height: 1.25,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w800,
        fontSize: 28.0,
        letterSpacing: useDyslexicFont ? 0.5 : 0.0,
        height: 1.3,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 24.0,
        letterSpacing: useDyslexicFont ? 0.4 : 0.0,
        height: 1.35,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 20.0,
        letterSpacing: useDyslexicFont ? 0.4 : 0.0,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600, // Avoid lightweight fonts (< w400) for readability
        fontSize: 18.0,
        letterSpacing: useDyslexicFont ? 0.8 : 0.5,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
        letterSpacing: useDyslexicFont ? 0.8 : 0.4,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
        letterSpacing: useDyslexicFont ? 0.7 : 0.3,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 16.0,
        letterSpacing: 1.0,
        height: 1.4,
      ),
    );
  }
}
