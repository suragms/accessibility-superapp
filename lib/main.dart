import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load client environment variables
  await dotenv.load(fileName: ".env");

  // Initialize the notification plugin for real OS-level notifications
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await NotificationService.initialize(flutterLocalNotificationsPlugin);

  // Initialize SharedPreferences on startup
  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const AccessibilitySuperApp(),
    ),
  );
}

class AccessibilitySuperApp extends ConsumerWidget {
  const AccessibilitySuperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsControllerProvider);

    ThemeData getThemeData() {
      switch (settings.themeMode) {
        case ThemeModeOption.light:
          return AppTheme.getLightTheme(useDyslexicFont: settings.useDyslexicFont);
        case ThemeModeOption.dark:
          return AppTheme.getDarkTheme(useDyslexicFont: settings.useDyslexicFont);
        case ThemeModeOption.highContrast:
          return AppTheme.getHighContrastTheme(useDyslexicFont: settings.useDyslexicFont);
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
