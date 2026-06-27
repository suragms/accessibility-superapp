import 'package:flutter/material.dart';

/// Design tokens designed accessibility-first.
/// Adapts spacing, borders, outlines, and interactive sizes dynamically
/// based on the user's active AccessibilityProfile.
class AccessibilityTokens {
  final double scale;

  const AccessibilityTokens({required this.scale});

  // --- Tap & Target Sizes (WCAG AAA Compliance: min 48x48dp) ---
  double get minTapTargetSize => (48.0 * scale).clamp(48.0, 72.0);
  double get iconButtonSize => (52.0 * scale).clamp(52.0, 80.0);

  // --- Dynamic Spacing Scale (scales margins slightly to avoid layout crunch) ---
  double get spaceXXSmall => 2.0 * (1.0 + (scale - 1.0) * 0.25);
  double get spaceXSmall => 4.0 * (1.0 + (scale - 1.0) * 0.3);
  double get spaceSmall => 8.0 * (1.0 + (scale - 1.0) * 0.4);
  double get spaceMedium => 16.0 * (1.0 + (scale - 1.0) * 0.5);
  double get spaceLarge => 24.0 * (1.0 + (scale - 1.0) * 0.5);
  double get spaceXLarge => 32.0 * (1.0 + (scale - 1.0) * 0.6);
  double get spaceXXLarge => 48.0 * (1.0 + (scale - 1.0) * 0.7);

  // --- Accessible Focus Outlines & Borders ---
  double get focusBorderWidth => 3.0; // High visibility focus outlines
  double get borderThicknessNormal => 1.5;
  double get borderThicknessBold => 2.5;

  double get cardCornerRadius => 12.0;
  double get buttonCornerRadius => 8.0;
  double get inputCornerRadius => 8.0;

  // Visual outline offsets
  double get focusOutlineOffset => 2.0;

  /// Retrieves the active tokens from the context.
  static AccessibilityTokens of(BuildContext context) {
    final scale = MediaQuery.textScaleFactorOf(context);
    return AccessibilityTokens(scale: scale);
  }
}
