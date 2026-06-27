import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AccessibilitySuperApp(),
    ),
  );
}

class AccessibilitySuperApp extends ConsumerWidget {
  const AccessibilitySuperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // In production architecture, these settings are dynamically watched from a user settings notifier
    const themeMode = ThemeModeOption.light;
    const useDyslexicFont = false;

    ThemeData getThemeData() {
      switch (themeMode) {
        case ThemeModeOption.light:
          return AppTheme.getLightTheme(useDyslexicFont: useDyslexicFont);
        case ThemeModeOption.dark:
          return AppTheme.getDarkTheme(useDyslexicFont: useDyslexicFont);
        case ThemeModeOption.highContrast:
          return AppTheme.getHighContrastTheme(useDyslexicFont: useDyslexicFont);
      }
    }

    return MaterialApp.router(
      title: 'Accessibility Super App',
      theme: getThemeData(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
