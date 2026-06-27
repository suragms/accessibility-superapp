import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/speech_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../data/repositories/speech_repository.dart';
import '../../domain/models/speech_config.dart';
import '../../domain/models/transcript_session.dart';

class SpeechState {
  final SpeechConfig config;
  final bool isListening;
  final List<String> captionLines;
  final String? exportPath;
  final String? errorMessage;

  const SpeechState({
    required this.config,
    required this.isListening,
    required this.captionLines,
    this.exportPath,
    this.errorMessage,
  });

  SpeechState copyWith({
    SpeechConfig? config,
    bool? isListening,
    List<String>? captionLines,
    String? exportPath,
    String? errorMessage,
  }) {
    return SpeechState(
      config: config ?? this.config,
      isListening: isListening ?? this.isListening,
      captionLines: captionLines ?? this.captionLines,
      exportPath: exportPath ?? this.exportPath,
      errorMessage: errorMessage, // Reset if null
    );
  }
}

/// Controller driving Caption Mode operations and synthesizer configuration.
class SpeechController extends StateNotifier<SpeechState> {
  final SpeechService speechService;
  final TtsService ttsService;
  final SpeechRepository speechRepository;

  SpeechController({
    required this.speechService,
    required this.ttsService,
    required this.speechRepository,
  }) : super(const SpeechState(
          config: SpeechConfig(),
          isListening: false,
          captionLines: [],
        )) {
    loadPreferences();
  }

  /// Loads stored configurations and applies parameters to synthesizer.
  Future<void> loadPreferences() async {
    final cached = await speechRepository.loadConfig();
    state = state.copyWith(config: cached);
    await _applyConfigToTts(cached);
  }

  /// Toggles continuous speech captions mic.
  Future<void> toggleCaptionMode() async {
    if (state.isListening) {
      await speechService.stopListening();
      state = state.copyWith(isListening: false);
    } else {
      state = state.copyWith(isListening: true, errorMessage: null);
      await speechService.startListening(
        localeId: state.config.localeCode,
        onResult: (text) {
          state = state.copyWith(
            captionLines: [...state.captionLines, text],
          );
        },
        onError: (err) {
          state = state.copyWith(isListening: false, errorMessage: err);
        },
      );
    }
  }

  /// Clears transcription lines buffer.
  void clearCaptions() {
    state = state.copyWith(captionLines: [], exportPath: null);
  }

  /// Adjusts speech speed scaling.
  Future<void> updateSpeechRate(double rate) async {
    final updated = state.config.copyWith(speechRate: rate);
    state = state.copyWith(config: updated);
    await speechRepository.saveConfig(updated);
    await ttsService.setSpeechRate(rate);
  }

  /// Adjusts synthesizer voice pitch.
  Future<void> updatePitch(double pitch) async {
    final updated = state.config.copyWith(pitch: pitch);
    state = state.copyWith(config: updated);
    await speechRepository.saveConfig(updated);
    // Note: FlutterTts has support for setPitch, we can invoke directly if required
  }

  /// Adjusts target speech recognition locale.
  Future<void> updateLocale(String localeCode) async {
    final updated = state.config.copyWith(localeCode: localeCode);
    state = state.copyWith(config: updated);
    await speechRepository.saveConfig(updated);
    await ttsService.setLanguage(localeCode);
  }

  /// Toggles noise cancellation settings wrapper.
  Future<void> toggleNoiseReduction(bool value) async {
    final updated = state.config.copyWith(noiseReductionEnabled: value);
    state = state.copyWith(config: updated);
    await speechRepository.saveConfig(updated);
  }

  /// Compiles lines buffer and saves local plain text file records.
  Future<void> exportTranscript() async {
    if (state.captionLines.isEmpty) {
      state = state.copyWith(errorMessage: 'No captions transcribed to export.');
      return;
    }

    final session = TranscriptSession(
      id: const Uuid().v4().substring(0, 8),
      timestamp: DateTime.now(),
      textLines: state.captionLines,
    );

    try {
      final file = await speechRepository.exportTranscript(session);
      state = state.copyWith(exportPath: file.path);
      await ttsService.speak('Transcript session exported successfully.');
    } catch (e) {
      state = state.copyWith(errorMessage: 'Transcript export failed: ${e.toString()}');
    }
  }

  Future<void> _applyConfigToTts(SpeechConfig config) async {
    await ttsService.setSpeechRate(config.speechRate);
    await ttsService.setLanguage(config.localeCode);
  }
}

// Provider definitions
final speechRepositoryProvider = Provider<SpeechRepository>((ref) {
  return SpeechRepository();
});

/// Riverpod provider for SpeechController.
final speechControllerProvider =
    StateNotifierProvider<SpeechController, SpeechState>((ref) {
  final speech = ref.watch(speechServiceProvider);
  final tts = ref.watch(ttsServiceProvider);
  final repo = ref.watch(speechRepositoryProvider);
  return SpeechController(
    speechService: speech,
    ttsService: tts,
    speechRepository: repo,
  );
});
