import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'text_theme.dart';

enum ThemeModeOption {
  light,
  dark,
  highContrast,
}

class AppTheme {
  AppTheme._();

  static ThemeData getLightTheme({required bool useDyslexicFont}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightOnSecondary,
        error: AppColors.lightError,
        onError: AppColors.lightOnError,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
      ),
      textTheme: AppTextTheme.buildTextTheme(useDyslexicFont: useDyslexicFont),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
      ),
      // Set high-contrast/large touch targets
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static ThemeData getDarkTheme({required bool useDyslexicFont}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnSecondary,
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
      ),
      textTheme: AppTextTheme.buildTextTheme(useDyslexicFont: useDyslexicFont),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static ThemeData getHighContrastTheme({required bool useDyslexicFont}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.hcPrimary,
        onPrimary: AppColors.hcOnPrimary,
        secondary: AppColors.hcSecondary,
        onSecondary: AppColors.hcOnSecondary,
        error: AppColors.hcError,
        onError: AppColors.hcOnError,
        surface: AppColors.hcSurface,
        onSurface: AppColors.hcTextPrimary,
      ),
      textTheme: AppTextTheme.buildTextTheme(useDyslexicFont: useDyslexicFont),
      scaffoldBackgroundColor: AppColors.hcBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.hcSurface,
        foregroundColor: AppColors.hcPrimary,
        elevation: 1,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
