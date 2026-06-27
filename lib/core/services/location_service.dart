import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../error/exceptions.dart';

/// Platform Service layer executing Geolocation lookups for SOS and caregiver visibility.
class LocationService {
  const LocationService();

  /// Requests permissions and retrieves high-accuracy GPS coordinates.
  /// Throws [LocationException] if permissions are denied or service is disabled.
  Future<Position> getCurrentPosition() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        throw const LocationException(
          message: 'Location services are disabled on device.',
          code: 'SERVICE_DISABLED',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw const LocationException(
            message: 'Location permission was denied.',
            code: 'PERMISSION_DENIED',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw const LocationException(
          message: 'Location permissions are permanently denied; cannot request.',
          code: 'PERMISSION_DENIED_FOREVER',
        );
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
    } on LocationException {
      rethrow;
    } catch (e) {
      throw LocationException(
        message: 'Unexpected location resolution error: ${e.toString()}',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }
}

/// Riverpod provider for the LocationService instance.
final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});
