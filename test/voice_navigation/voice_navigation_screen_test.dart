import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:accessibility_super_app/core/accessibility/accessibility_engine.dart';
import 'package:accessibility_super_app/core/theme/accessibility_profile.dart';
import 'package:accessibility_super_app/core/widgets/accessible_button.dart';
import 'package:accessibility_super_app/core/router/route_names.dart';
import 'package:accessibility_super_app/core/services/speech_service.dart';
import 'package:accessibility_super_app/core/services/tts_service.dart';
import 'package:accessibility_super_app/features/voice_navigation/presentation/screens/voice_navigation_screen.dart';

// Fake implementations of platform services for reliable testing
class FakeSpeechService extends SpeechService {
  bool _isListening = false;
  bool _isInitialized = true;
  void Function(String resultText)? onResultCallback;

  @override
  bool get isListening => _isListening;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<bool> initialize({
    required Function(String status) onStatus,
    required Function(String errorMsg) onError,
  }) async {
    _isInitialized = true;
    return true;
  }

  @override
  Future<void> startListening({
    required Function(String resultText) onResult,
    required Function(String errorMsg) onError,
    String? localeId,
  }) async {
    _isListening = true;
    onResultCallback = onResult;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  void triggerSpeechResult(String text) {
    if (onResultCallback != null) {
      onResultCallback!(text);
    }
  }
}

class FakeTtsService implements TtsService {
  final List<String> spokenLines = [];

  @override
  Future<void> speak(String text) async {
    spokenLines.add(text);
  }

  @override
  Future<void> stop() async {
    spokenLines.clear();
  }

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}
}

class FakeAccessibilityEngine extends AccessibilityEngine {
  FakeAccessibilityEngine()
      : super(
          profile: const AccessibilityProfile(
            useHighContrast: false,
            textScaleFactor: 1.0,
            hapticsEnabled: false,
          ),
        );

  final List<String> announcements = [];

  @override
  Future<void> announce(String message) async {
    announcements.add(message);
  }

  @override
  Future<void> triggerFeedback(
    AccessibilityFeedbackType type, {
    String? announcementMessage,
  }) async {
    if (announcementMessage != null) {
      announcements.add(announcementMessage);
    }
  }
}

void main() {
  group('VoiceNavigationScreen Widget & Navigation Integration Tests', () {
    late FakeSpeechService fakeSpeech;
    late FakeTtsService fakeTts;
    late FakeAccessibilityEngine fakeAccessibility;

    setUp(() {
      fakeSpeech = FakeSpeechService();
      fakeTts = FakeTtsService();
      fakeAccessibility = FakeAccessibilityEngine();
    });

    // Helper to build test environment
    Widget buildTestApp(GoRouter router) {
      return ProviderScope(
        overrides: [
          speechServiceProvider.overrideWithValue(fakeSpeech),
          ttsServiceProvider.overrideWithValue(fakeTts),
          accessibilityEngineProvider.overrideWithValue(fakeAccessibility),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('Verify screen initialization, mic toggle, and status announcements', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/voice-navigation',
        routes: [
          GoRoute(
            path: '/voice-navigation',
            name: RouteNames.voiceNavigation,
            builder: (context, state) => const VoiceNavigationScreen(),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      // Check initial screen setup
      expect(find.text('Voice Navigation'), findsOneWidget);
      expect(find.text('Voice navigation is idle.'), findsOneWidget);

      // Tap mic to start listening
      expect(find.byIcon(Icons.mic), findsOneWidget);
      
      await tester.tap(find.byType(AccessibleButton));
      await tester.pump();

      // Should be listening for wake word now
      expect(fakeSpeech.isListening, isTrue);
      expect(find.text('Listening...\nSay "Assistant" to begin.'), findsOneWidget);
    });

    testWidgets('Verify Wake-Word detection transition', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/voice-navigation',
        routes: [
          GoRoute(
            path: '/voice-navigation',
            name: RouteNames.voiceNavigation,
            builder: (context, state) => const VoiceNavigationScreen(),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      // Start listening
      await tester.tap(find.byType(AccessibleButton));
      await tester.pump();

      // Trigger wake word
      fakeSpeech.triggerSpeechResult('assistant');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Screen state should update to wake word detected
      expect(find.text('Wake word detected!\nSpeak your command now.'), findsOneWidget);
      expect(fakeTts.spokenLines.last, contains('how can I help you'));
    });

    testWidgets('Verify intent routing for all mapped navigation paths', (WidgetTester tester) async {
      final testCases = {
        'open dashboard': '/home',
        'chat assistant helper': '/ai-assistant',
        'show speech live captions': '/speech-to-text',
        'list my medications': '/medications',
        'contact caregiver connection': '/caregiver',
        'open accessibility settings': '/settings',
        'trigger emergency sos': '/sos',
      };

      for (final entry in testCases.entries) {
        final speechCommand = entry.key;
        final targetPath = entry.value;

        final router = GoRouter(
          initialLocation: '/voice-navigation',
          routes: [
            GoRoute(
              path: '/voice-navigation',
              name: RouteNames.voiceNavigation,
              builder: (context, state) => const VoiceNavigationScreen(),
            ),
            GoRoute(
              path: '/home',
              name: RouteNames.home,
              builder: (context, state) => const Text('Home Page'),
            ),
            GoRoute(
              path: '/ai-assistant',
              name: RouteNames.aiAssistant,
              builder: (context, state) => const Text('AI Page'),
            ),
            GoRoute(
              path: '/speech-to-text',
              name: RouteNames.speechToText,
              builder: (context, state) => const Text('STT Page'),
            ),
            GoRoute(
              path: '/medications',
              name: RouteNames.medicationList,
              builder: (context, state) => const Text('Meds Page'),
            ),
            GoRoute(
              path: '/caregiver',
              name: RouteNames.caregiver,
              builder: (context, state) => const Text('Caregiver Page'),
            ),
            GoRoute(
              path: '/settings',
              name: RouteNames.settings,
              builder: (context, state) => const Text('Settings Page'),
            ),
            GoRoute(
              path: '/sos',
              name: RouteNames.sos,
              builder: (context, state) => const Text('SOS Page'),
            ),
          ],
        );

        await tester.pumpWidget(buildTestApp(router));
        await tester.pumpAndSettle();

        // 1. Activate microphone
        await tester.tap(find.byType(AccessibleButton));
        await tester.pump();

        // 2. Trigger wake word
        fakeSpeech.triggerSpeechResult('assistant');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        // 3. Trigger navigation command
        fakeSpeech.triggerSpeechResult(speechCommand);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        // 4. Verify GoRouter navigated to correct destination
        expect(router.routeInformationProvider.value.uri.path, equals(targetPath));
      }
    });

    testWidgets('Verify goBack intent pops current overlay', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            name: RouteNames.home,
            builder: (context, state) => const Text('Home Dashboard'),
          ),
          GoRoute(
            path: '/voice-navigation',
            name: RouteNames.voiceNavigation,
            builder: (context, state) => const VoiceNavigationScreen(),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      // Go to voice navigation page
      router.goNamed(RouteNames.voiceNavigation);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, equals('/voice-navigation'));

      // Start listening
      await tester.tap(find.byType(AccessibleButton));
      await tester.pump();

      // Trigger wake word
      fakeSpeech.triggerSpeechResult('assistant');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Trigger "go back" command
      fakeSpeech.triggerSpeechResult('go back to previous screen');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Should have popped back to home
      expect(router.routeInformationProvider.value.uri.path, equals('/home'));
    });
  });
}
