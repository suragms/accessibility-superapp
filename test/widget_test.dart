import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:accessibility_super_app/main.dart';
import 'package:accessibility_super_app/core/database/app_database.dart';
import 'package:accessibility_super_app/features/auth/data/repositories/auth_repository.dart';
import 'package:accessibility_super_app/features/settings/presentation/controllers/settings_controller.dart';

class MockAuthRepository extends AuthRepository {
  MockAuthRepository()
      : super(
          dio: Dio(),
          secureStorage: const FlutterSecureStorage(),
          database: AppDatabase(),
        );

  @override
  Future<UserSession?> restoreSession() async => null;
}

void main() {
  testWidgets('Smoke test for Accessibility Super App initialization', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_has_seen_onboarding': true,
    });
    final sharedPrefs = await SharedPreferences.getInstance();
    final mockAuthRepo = MockAuthRepository();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
        child: const AccessibilitySuperApp(),
      ),
    );

    // Let the router resolve the initial location (/home)
    await tester.pumpAndSettle();

    // Verify that the Login screen is loaded
    expect(find.text('Login'), findsOneWidget);
  });
}
