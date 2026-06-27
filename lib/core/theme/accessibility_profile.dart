import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable model representing the active Accessibility configuration of the app.
@immutable
class AccessibilityProfile {
  final ThemeMode themeMode;
  final bool useHighContrast;
  final double textScaleFactor;
  final bool useDyslexicFont;
  final bool disableAnimations;
  final bool speakOnTap;
  final bool hapticsEnabled;

  const AccessibilityProfile({
    this.themeMode = ThemeMode.system,
    this.useHighContrast = false,
    this.textScaleFactor = 1.0,
    this.useDyslexicFont = false,
    this.disableAnimations = false,
    this.speakOnTap = false,
    this.hapticsEnabled = true,
  });

  AccessibilityProfile copyWith({
    ThemeMode? themeMode,
    bool? useHighContrast,
    double? textScaleFactor,
    bool? useDyslexicFont,
    bool? disableAnimations,
    bool? speakOnTap,
    bool? hapticsEnabled,
  }) {
    return AccessibilityProfile(
      themeMode: themeMode ?? this.themeMode,
      useHighContrast: useHighContrast ?? this.useHighContrast,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      useDyslexicFont: useDyslexicFont ?? this.useDyslexicFont,
      disableAnimations: disableAnimations ?? this.disableAnimations,
      speakOnTap: speakOnTap ?? this.speakOnTap,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessibilityProfile &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          useHighContrast == other.useHighContrast &&
          textScaleFactor == other.textScaleFactor &&
          useDyslexicFont == other.useDyslexicFont &&
          disableAnimations == other.disableAnimations &&
          speakOnTap == other.speakOnTap &&
          hapticsEnabled == other.hapticsEnabled;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      useHighContrast.hashCode ^
      textScaleFactor.hashCode ^
      useDyslexicFont.hashCode ^
      disableAnimations.hashCode ^
      speakOnTap.hashCode ^
      hapticsEnabled.hashCode;
}

/// StateNotifier managing accessibility profiles dynamically.
class AccessibilityProfileNotifier extends StateNotifier<AccessibilityProfile> {
  AccessibilityProfileNotifier() : super(const AccessibilityProfile());

  void updateThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleHighContrast(bool enabled) {
    state = state.copyWith(useHighContrast: enabled);
  }

  void updateTextScaleFactor(double factor) {
    // Restrict within comfortable limits (1.0x to 2.5x)
    final clampedFactor = factor.clamp(1.0, 2.5);
    state = state.copyWith(textScaleFactor: clampedFactor);
  }

  void toggleDyslexicFont(bool enabled) {
    state = state.copyWith(useDyslexicFont: enabled);
  }

  void toggleAnimations(bool disabled) {
    state = state.copyWith(disableAnimations: disabled);
  }

  void toggleSpeakOnTap(bool enabled) {
    state = state.copyWith(speakOnTap: enabled);
  }

  void toggleHaptics(bool enabled) {
    state = state.copyWith(hapticsEnabled: enabled);
  }
}

/// Global provider for accessing and modifying the Accessibility Settings profile.
final accessibilityProfileProvider =
    StateNotifierProvider<AccessibilityProfileNotifier, AccessibilityProfile>((ref) {
  return AccessibilityProfileNotifier();
});
