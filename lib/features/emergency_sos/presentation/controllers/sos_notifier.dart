import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';

/// Sealed class defining the reactive states of the SOS broadcast pipeline.
sealed class SosState {
  const SosState();
}

class SosIdle extends SosState {
  const SosIdle();
}

class SosSending extends SosState {
  const SosSending();
}

class SosSent extends SosState {
  final DateTime timestamp;
  const SosSent(this.timestamp);
}

class SosError extends SosState {
  final String error;
  const SosError(this.error);
}

/// Presentation controller managing the critical Emergency SOS trigger state.
class SosNotifier extends StateNotifier<SosState> {
  final LocationService locationService;

  SosNotifier({required this.locationService})
      : super(const SosIdle());

  /// Triggers the emergency broadcast sequence:
  /// 1. Immediately grabs precise geolocation.
  /// 2. Dispatches physical SMS warnings to emergency contacts.
  /// 3. Communicates the coordinate payload to the cloud API.
  Future<void> triggerSos() async {
    state = const SosSending();
    try {
      // 1. Locate User coordinates
      final position = await locationService.getCurrentPosition();

      // 2. Perform emergency notifications broadcast (SMS / Push API call Mock)
      // In production, this would call repositories linked to SMS adapters & Cloud endpoints
      await _dispatchEmergencyAlerts(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      state = SosSent(DateTime.now());
    } catch (e) {
      state = SosError(e.toString());
    }
  }

  /// Reset the SOS state back to Idle after resolution
  void reset() {
    state = const SosIdle();
  }

  Future<void> _dispatchEmergencyAlerts({
    required double latitude,
    required double longitude,
  }) async {
    // Simulated asynchronous transmission latency
    await Future.delayed(const Duration(milliseconds: 1200));
    // Log trace of dispatch
    debugPrint('EMERGENCY BROADCAST SUCCESSFULLY SENT: Lat: $latitude, Long: $longitude');
  }
}

/// Provider for the SosNotifier, exposing state to the presentation widgets.
final sosNotifierProvider = StateNotifierProvider<SosNotifier, SosState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return SosNotifier(locationService: locationService);
});
