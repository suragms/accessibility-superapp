import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/accessibility_profile.dart';

enum AccessibilityFeedbackType {
  success,
  warning,
  error,
  click,
}

/// The core Accessibility Engine coordinating screen-reader announcements
/// and haptic feedback profiles.
class AccessibilityEngine {
  final AccessibilityProfile profile;

  const AccessibilityEngine({required this.profile});

  /// Programmatically broadcasts a message directly to TalkBack / VoiceOver.
  /// Standardizes text announcements across layouts.
  Future<void> announce(String message) async {
    // Announce to platform-native accessibility channels
    await SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Triggers a multimodal haptic and spoken confirmation.
  Future<void> triggerFeedback(
    AccessibilityFeedbackType type, {
    String? announcementMessage,
  }) async {
    // 1. Spoken screen-reader announcement if specified
    if (announcementMessage != null) {
      await announce(announcementMessage);
    }

    // 2. Tactile haptic pulse matching feedback type if enabled in profile settings
    if (!profile.hapticsEnabled) return;

    switch (type) {
      case AccessibilityFeedbackType.success:
        await HapticFeedback.vibrate(); // Long confirmation
        break;
      case AccessibilityFeedbackType.warning:
        await HapticFeedback.mediumImpact();
        break;
      case AccessibilityFeedbackType.error:
        // Double pulse vibration for warning/critical alerts
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
        break;
      case AccessibilityFeedbackType.click:
        await HapticFeedback.lightImpact();
        break;
    }
  }

  /// Helper to trigger success profiles
  Future<void> confirmSuccess(String message) async {
    await triggerFeedback(
      AccessibilityFeedbackType.success,
      announcementMessage: 'Success: $message',
    );
  }

  /// Helper to trigger warning profiles
  Future<void> confirmWarning(String message) async {
    await triggerFeedback(
      AccessibilityFeedbackType.warning,
      announcementMessage: 'Warning: $message',
    );
  }

  /// Helper to trigger critical error profiles
  Future<void> confirmError(String message) async {
    await triggerFeedback(
      AccessibilityFeedbackType.error,
      announcementMessage: 'Error: $message',
    );
  }
}

/// Riverpod provider to fetch AccessibilityEngine.
final accessibilityEngineProvider = Provider<AccessibilityEngine>((ref) {
  final profile = ref.watch(accessibilityProfileProvider);
  return AccessibilityEngine(profile: profile);
});
