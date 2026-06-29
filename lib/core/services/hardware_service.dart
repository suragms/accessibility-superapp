import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Platform Hardware Capabilities Service.
///
/// Uses `url_launcher` to open the native SMS and Phone apps via `sms:` and
/// `tel:` URI schemes. This is the standard, App Store / Play Store-compliant
/// approach: the Messages or Phone app opens with the message/number pre-filled
/// and the user (or caregiver) taps send/call once the relevant app is visible.
///
/// Fully silent background SMS sending requires `SEND_SMS` permissions that are
/// heavily restricted on both iOS and Android and would likely cause app-store
/// rejection. The `sms:` URI launch avoids those dangerous permissions entirely
/// while still achieving the accessibility goal of quickly alerting contacts.
///
/// Similarly, `tel:` URI launches do NOT require the `CALL_PHONE` dangerous
/// permission — they open the system dialer with the number pre-filled.
class HardwareService {
  HardwareService();

  final Battery _battery = Battery();

  /// Returns the real device battery percentage as a `double` (0.0–100.0).
  /// Falls back to `-1.0` if the platform cannot report the value.
  Future<double> getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      return level.toDouble();
    } catch (_) {
      return -1.0;
    }
  }

  /// Opens the native Messages app with the given [message] pre-filled for
  /// [phone]. Returns `true` if the SMS URI was launched successfully.
  ///
  /// The message is URL-encoded so that special characters are preserved.
  Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    try {
      final encodedMessage = Uri.encodeComponent(message);
      final uri = Uri.parse('sms:$phone?body=$encodedMessage');
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  /// Opens the native Phone / dialer app with [phone] pre-filled.
  /// Returns `true` if the `tel:` URI was launched successfully.
  Future<bool> makeCall({required String phone}) async {
    try {
      final uri = Uri.parse('tel:$phone');
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}

/// Riverpod provider for HardwareService.
final hardwareServiceProvider = Provider<HardwareService>((ref) {
  return HardwareService();
});
