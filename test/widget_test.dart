import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:accessibility_super_app/main.dart';

void main() {
  testWidgets('Smoke test for Accessibility Super App initialization', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AccessibilitySuperApp(),
      ),
    );

    // Let the router resolve the initial location (/home)
    await tester.pumpAndSettle();

    // Verify that the Login screen is loaded
    expect(find.text('Login'), findsOneWidget);
  });
}
