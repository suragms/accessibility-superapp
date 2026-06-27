import 'package:flutter_test/flutter_test.dart';

import 'package:accessibility_super_app/features/speech/domain/models/speech_config.dart';
import 'package:accessibility_super_app/features/speech/domain/models/transcript_session.dart';

void main() {
  group('SpeechConfig & TranscriptSession Unit Tests', () {
    test('Verify SpeechConfig default values and copyWith parameters', () {
      const config = SpeechConfig();
      expect(config.speechRate, equals(0.5));
      expect(config.pitch, equals(1.0));
      expect(config.localeCode, equals('en-US'));
      expect(config.voiceGender, equals(VoiceGender.female));
      expect(config.noiseReductionEnabled, isFalse);

      final updated = config.copyWith(
        speechRate: 0.75,
        noiseReductionEnabled: true,
        voiceGender: VoiceGender.male,
      );
      expect(updated.speechRate, equals(0.75));
      expect(updated.pitch, equals(1.0)); // Unchanged
      expect(updated.voiceGender, equals(VoiceGender.male));
      expect(updated.noiseReductionEnabled, isTrue);
    });

    test('Verify SpeechConfig JSON serialization and deserialization', () {
      const config = SpeechConfig(
        speechRate: 0.8,
        pitch: 1.2,
        localeCode: 'ml-IN',
        voiceGender: VoiceGender.male,
        noiseReductionEnabled: true,
      );

      final jsonMap = config.toJson();
      final decoded = SpeechConfig.fromJson(jsonMap);

      expect(decoded.speechRate, equals(0.8));
      expect(decoded.pitch, equals(1.2));
      expect(decoded.localeCode, equals('ml-IN'));
      expect(decoded.voiceGender, equals(VoiceGender.male));
      expect(decoded.noiseReductionEnabled, isTrue);
    });

    test('Verify TranscriptSession JSON and text properties', () {
      final session = TranscriptSession(
        id: 'mock-session-77',
        timestamp: DateTime.parse('2026-06-27T12:00:00Z'),
        textLines: ['Hello world', 'This is live caption text', 'Ending recording.'],
      );

      expect(
        session.fullText,
        equals('Hello world\nThis is live caption text\nEnding recording.'),
      );

      final jsonMap = session.toJson();
      final decoded = TranscriptSession.fromJson(jsonMap);

      expect(decoded.id, equals('mock-session-77'));
      expect(decoded.textLines, hasLength(3));
      expect(decoded.textLines[1], equals('This is live caption text'));
    });
  });
}
