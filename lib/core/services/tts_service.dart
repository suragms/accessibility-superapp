import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A production-grade wrapper service for Text-To-Speech (TTS).
/// Key Features:
/// 1. Exposes speech configuration parameters (pitch, speed rate, volume).
/// 2. Manages native engine state (speaking, stopped).
/// 3. Provides clean programmatic interfaces for spoken alerts.
class TtsService {
  final FlutterTts _flutterTts;

  TtsService({FlutterTts? flutterTts}) : _flutterTts = flutterTts ?? FlutterTts() {
    _initTts();
  }

  void _initTts() {
    // Standardize default configurations suitable for screen-reader scaling
    _flutterTts.setVolume(1.0);
    _flutterTts.setSpeechRate(0.5); // 0.5 is standard human speed in FlutterTts
    _flutterTts.setPitch(1.0);
  }

  /// Sets TTS language locale.
  Future<void> setLanguage(String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
  }

  /// Adjusts speech rate (0.0 to 1.0).
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  /// Speaks the provided text content.
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _flutterTts.stop(); // Stop current speech to allow atomic announcement
    await _flutterTts.speak(text);
  }

  /// Silences the active speaker immediately.
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

/// Riverpod provider for TtsService.
final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});
