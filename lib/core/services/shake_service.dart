import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shake/shake.dart';

/// Platform Shake detection accelerometer stream listener.
class ShakeService {
  ShakeDetector? _detector;

  /// Starts listening to hardware movements, executes alert callbacks on threshold triggers.
  void startListening({
    required VoidCallback onPhoneShaken,
    double threshold = 2.7,
  }) {
    try {
      _detector = ShakeDetector.autoStart(
        onPhoneShake: onPhoneShaken,
        shakeThresholdGravity: threshold,
      );
    } catch (e) {
      // Gracefully bypass if running on emulator / testing environments
    }
  }

  /// Silences sensors.
  void stopListening() {
    _detector?.stopListening();
  }
}

/// Riverpod provider for ShakeService.
final shakeServiceProvider = Provider<ShakeService>((ref) {
  return ShakeService();
});
