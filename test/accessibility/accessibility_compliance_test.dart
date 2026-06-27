import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:accessibility_super_app/core/widgets/accessible_button.dart';
import 'package:accessibility_super_app/core/widgets/accessible_text_field.dart';

void main() {
  group('WCAG Accessibility Compliance Tests', () {
    testWidgets('Verify AccessibleButton meets tap target Guidelines', (WidgetTester tester) async {
      // Build an AccessibleButton inside a clean material wrapper context.
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AccessibleButton(
                  onPressed: () {},
                  semanticLabel: 'Submit form action.',
                  child: const Text('SUBMIT'),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify that tap targets meet iOS/Android guideline expectations (minimum 48dp).
      // Under Flutter test bindings, meetsGuideline audits size constraints dynamically.
      await tester.pumpAndSettle();

      final handle = tester.ensureSemantics();
      
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      expect(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('Verify AccessibleTextField meets accessibility Guidelines', (WidgetTester tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AccessibleTextField(
                  controller: controller,
                  focusNode: focusNode,
                  label: 'Secure PIN Number',
                  hintText: 'Enter 4 digit code',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final handle = tester.ensureSemantics();

      // Check text contrast guides and touch bounds
      expect(tester, meetsGuideline(textContrastGuideline));
      expect(tester, meetsGuideline(androidTapTargetGuideline));

      handle.dispose();
    });
  });
}
