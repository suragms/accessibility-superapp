import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A production-ready adapter wrapping the SpeechToText native microphone listeners.
/// Incorporates permission flows, locale selection, and error handling.
class SpeechService {
  final SpeechToText _speechToText;
  bool _isInitialized = false;

  SpeechService({SpeechToText? speechToText}) : _speechToText = speechToText ?? SpeechToText();

  bool get isListening => _speechToText.isListening;
  bool get isInitialized => _isInitialized;

  /// Initializes the STT native components.
  Future<bool> initialize({
    required Function(String status) onStatus,
    required Function(String errorMsg) onError,
  }) async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) => onStatus(status),
        onError: (errorNotification) => onError(errorNotification.errorMsg),
        debugLogging: true,
      );
      return _isInitialized;
    } catch (e) {
      onError('Microphone speech initialization failed: ${e.toString()}');
      _isInitialized = false;
      return false;
    }
  }

  /// Begins listening to mic feed.
  Future<void> startListening({
    required Function(String resultText) onResult,
    required Function(String errorMsg) onError,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      final success = await initialize(onStatus: (_) {}, onError: onError);
      if (!success) return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 4),
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Silences the active mic listener feed.
  Future<void> stopListening() async {
    if (!_isInitialized) return;
    await _speechToText.stop();
  }
}

/// Riverpod provider for SpeechService.
final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});
