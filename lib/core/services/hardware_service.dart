import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Platform Hardware Capabilities Service wrapper.
class HardwareService {
  const HardwareService();

  /// Mock GPS / System Battery Life percentage readout.
  Future<double> getBatteryLevel() async {
    // In production, uses battery_plus platform method channels.
    return 88.0; 
  }

  /// Sends a background SMS log message.
  Future<bool> sendSms({required String phone, required String message}) async {
    // In production, uses flutter_sms or native platform channels to execute direct SMS sending.
    return true; 
  }

  /// Launches platform native phone dialer loops.
  Future<bool> makeCall({required String phone}) async {
    // In production, uses url_launcher with 'tel:$phone' intent configurations.
    return true;
  }
}

/// Riverpod provider for HardwareService.
final hardwareServiceProvider = Provider<HardwareService>((ref) {
  return const HardwareService();
});
