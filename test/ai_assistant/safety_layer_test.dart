import 'package:flutter_test/flutter_test.dart';

import 'package:accessibility_super_app/features/ai_assistant/domain/services/safety_layer.dart';

void main() {
  group('SafetyLayer Moderation and Emergency Interception Tests', () {
    test('Verify standard safe prompts pass validation checks', () {
      final result = SafetyLayer.checkPrompt('Can you plan my tasks for today?');
      expect(result.isSafe, isTrue);
      expect(result.isEmergency, isFalse);
      expect(result.filteredText, equals('Can you plan my tasks for today?'));
    });

    test('Verify hate speech triggers safety blocks and isSafe false', () {
      final result = SafetyLayer.checkPrompt('This is a racist hate speech message');
      expect(result.isSafe, isFalse);
      expect(result.isEmergency, isFalse);
      expect(result.alertMessage, contains('violates our safety policy'));
    });

    test('Verify health crisis terms trigger emergency flags', () {
      final result = SafetyLayer.checkPrompt('I think I am having a heart attack right now');
      expect(result.isSafe, isTrue); // Emergency warning is not an explicit policy violation
      expect(result.isEmergency, isTrue);
      expect(result.alertMessage, contains('trigger an emergency SOS alert'));
    });

    test('Verify self harm warnings trigger emergency flags', () {
      final result = SafetyLayer.checkPrompt('I want to hurt myself');
      expect(result.isSafe, isTrue);
      expect(result.isEmergency, isTrue);
      expect(result.alertMessage, contains('trigger an emergency SOS alert'));
    });
  });
}
