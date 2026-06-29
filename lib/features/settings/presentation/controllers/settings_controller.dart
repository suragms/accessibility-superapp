import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

/// Provider for SharedPreferences. Must be overridden in main.dart on startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been overridden in ProviderScope');
});

/// Immutable settings state.
class SettingsState {
  final ThemeModeOption themeMode;
  final bool useDyslexicFont;
  final bool hasSeenOnboarding;

  const SettingsState({
    required this.themeMode,
    required this.useDyslexicFont,
    required this.hasSeenOnboarding,
  });

  SettingsState copyWith({
    ThemeModeOption? themeMode,
    bool? useDyslexicFont,
    bool? hasSeenOnboarding,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      useDyslexicFont: useDyslexicFont ?? this.useDyslexicFont,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }
}

/// Controller managing accessibility options and onboarding preferences.
class SettingsController extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  static const _themeKey = 'settings_theme_mode';
  static const _dyslexicKey = 'settings_use_dyslexic_font';
  static const _onboardingKey = 'settings_has_seen_onboarding';

  SettingsController(this._prefs)
      : super(SettingsState(
          themeMode: _loadThemeMode(_prefs),
          useDyslexicFont: _prefs.getBool(_dyslexicKey) ?? false,
          hasSeenOnboarding: _prefs.getBool(_onboardingKey) ?? false,
        ));

  static ThemeModeOption _loadThemeMode(SharedPreferences prefs) {
    final val = prefs.getString(_themeKey);
    if (val == null) return ThemeModeOption.light;
    return ThemeModeOption.values.firstWhere(
      (e) => e.name == val,
      orElse: () => ThemeModeOption.light,
    );
  }

  /// Sets the application theme mode option.
  void setThemeMode(ThemeModeOption mode) {
    _prefs.setString(_themeKey, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  /// Sets whether the dyslexic-friendly font is active.
  void toggleDyslexicFont(bool enabled) {
    _prefs.setBool(_dyslexicKey, enabled);
    state = state.copyWith(useDyslexicFont: enabled);
  }

  /// Sets the onboarding as completed.
  void completeOnboarding() {
    _prefs.setBool(_onboardingKey, true);
    state = state.copyWith(hasSeenOnboarding: true);
  }
}

/// Riverpod provider for SettingsController.
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsController(prefs);
});
