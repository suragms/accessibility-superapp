import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/accessibility/accessibility_engine.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../domain/command_intent.dart';
import '../../domain/command_parser.dart';

class VoiceNavigationState {
  final bool isListening;
  final bool wakeWordActive;
  final String lastCommand;
  final CommandIntent lastIntent;
  final String? errorMessage;

  const VoiceNavigationState({
    required this.isListening,
    required this.wakeWordActive,
    required this.lastCommand,
    required this.lastIntent,
    this.errorMessage,
  });

  VoiceNavigationState copyWith({
    bool? isListening,
    bool? wakeWordActive,
    String? lastCommand,
    CommandIntent? lastIntent,
    String? errorMessage,
  }) {
    return VoiceNavigationState(
      isListening: isListening ?? this.isListening,
      wakeWordActive: wakeWordActive ?? this.wakeWordActive,
      lastCommand: lastCommand ?? this.lastCommand,
      lastIntent: lastIntent ?? this.lastIntent,
      errorMessage: errorMessage, // Reset if null
    );
  }
}

/// The presentation controller driving the Voice Command pipeline.
class VoiceNavigationController extends StateNotifier<VoiceNavigationState> {
  final SpeechService speechService;
  final TtsService ttsService;
  final AccessibilityEngine accessibilityEngine;
  final CommandParser commandParser;

  static const String _wakeWord = 'assistant';

  VoiceNavigationController({
    required this.speechService,
    required this.ttsService,
    required this.accessibilityEngine,
    CommandParser? commandParser,
  })  : commandParser = commandParser ?? CommandParser(),
        super(const VoiceNavigationState(
          isListening: false,
          wakeWordActive: false,
          lastCommand: '',
          lastIntent: CommandIntent.unknown,
        ));

  /// Activates command listening loop.
  Future<void> startListening({String? localeId}) async {
    state = state.copyWith(isListening: true, errorMessage: null);

    await speechService.startListening(
      localeId: localeId,
      onResult: (text) => _processSpeechResult(text),
      onError: (error) {
        state = state.copyWith(isListening: false, errorMessage: error);
        accessibilityEngine.confirmError('Speech listener error.');
      },
    );
  }

  /// Silences listening mic stream.
  Future<void> stopListening() async {
    await speechService.stopListening();
    state = state.copyWith(isListening: false);
  }

  /// Resets intent state trackers.
  void clearLastIntent() {
    state = state.copyWith(
      lastIntent: CommandIntent.unknown,
      lastCommand: '',
    );
  }

  Future<void> _processSpeechResult(String text) async {
    final cleanText = text.trim().toLowerCase();

    // 1. Wake-word processing if not active yet
    if (!state.wakeWordActive) {
      if (cleanText.contains(_wakeWord)) {
        state = state.copyWith(wakeWordActive: true);
        
        // Multi-modal feedback confirmation
        await accessibilityEngine.triggerFeedback(AccessibilityFeedbackType.success);
        await ttsService.speak('Yes, how can I help you?');
        
        // Restart speech loop for target command
        await startListening();
      } else {
        // Did not match wake word, keep listening
        state = state.copyWith(lastCommand: text);
      }
      return;
    }

    // 2. Wake word is active: process commands
    final intent = commandParser.parse(cleanText);
    state = state.copyWith(
      lastCommand: text,
      lastIntent: intent,
      wakeWordActive: false, // Reset wake word for next command session
      isListening: false,
    );

    await _executeCommandActions(intent, text);
  }

  Future<void> _executeCommandActions(CommandIntent intent, String utterance) async {
    switch (intent) {
      case CommandIntent.home:
        await ttsService.speak('Opening dashboard.');
        await accessibilityEngine.triggerFeedback(AccessibilityFeedbackType.success);
        break;
      case CommandIntent.aiAssistant:
        await ttsService.speak('Opening assistant helper.');
        await accessibilityEngine.triggerFeedback(AccessibilityFeedbackType.success);
        break;
      case CommandIntent.speechToText:
        await ttsService.speak('Opening speech to text captions.');
        await accessibilityEngine.triggerFeedback(AccessibilityFeedbackType.success);
        break;
      case CommandIntent.medications:
        await ttsService.speak('Opening medicine list.');
        await accessibilityEngine.triggerFeedback(AccessibilityFeedbackType.success);
        break;
      case CommandIntent.caregiver:
        await ttsService.speak('Opening caregiver connections.');
        await accessibilityEngine.triggerFeedback(AccessibilityFeedbackType.success);
        break;
      case CommandIntent.settings:
        await ttsService.speak('Opening accessibility options settings.');
        await accessibilityEngine.triggerFeedback(AccessibilityFeedbackType.success);
        break;
      case CommandIntent.sos:
        await ttsService.speak('Alert. Dispatching emergency SOS broadcasts.');
        await accessibilityEngine.triggerFeedback(AccessibilityFeedbackType.error);
        break;
      case CommandIntent.goBack:
        await ttsService.speak('Returning back.');
        await accessibilityEngine.triggerFeedback(AccessibilityFeedbackType.click);
        break;
      case CommandIntent.unknown:
        await ttsService.speak('Sorry, command not recognized: $utterance');
        await accessibilityEngine.triggerFeedback(AccessibilityFeedbackType.warning);
        break;
    }
  }
}

/// Riverpod provider to fetch VoiceNavigationController.
final voiceNavigationControllerProvider =
    StateNotifierProvider<VoiceNavigationController, VoiceNavigationState>((ref) {
  final speech = ref.watch(speechServiceProvider);
  final tts = ref.watch(ttsServiceProvider);
  final accessibility = ref.watch(accessibilityEngineProvider);
  return VoiceNavigationController(
    speechService: speech,
    ttsService: tts,
    accessibilityEngine: accessibility,
  );
});
