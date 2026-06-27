class SafetyResult {
  final bool isSafe;
  final bool isEmergency;
  final String? filteredText;
  final String? alertMessage;

  const SafetyResult({
    required this.isSafe,
    required this.isEmergency,
    this.filteredText,
    this.alertMessage,
  });
}

/// Safety and Moderation verification engine.
/// Scans prompts for inappropriate words and intercepts safety crises to direct to SOS triggers.
class SafetyLayer {
  static const List<String> _emergencyKeywords = [
    'heart attack',
    'chest pain',
    'stroke',
    'bleeding',
    'dying',
    'emergency',
    'call 911',
    'call 112',
    'police',
    'fire',
    'suicide',
    'kill myself',
    'hurt myself',
  ];

  static const List<String> _blockedKeywords = [
    'hate speech',
    'violence',
    'racist',
    'sexist',
  ];

  /// Scans prompt content and returns safety classifications.
  static SafetyResult checkPrompt(String input) {
    final text = input.trim().toLowerCase();
    if (text.isEmpty) {
      return const SafetyResult(isSafe: true, isEmergency: false);
    }

    // 1. Scan for critical health/safety emergencies
    for (final word in _emergencyKeywords) {
      if (text.contains(word)) {
        return const SafetyResult(
          isSafe: true,
          isEmergency: true,
          alertMessage: 'I detected a potential emergency. Do you need to trigger an emergency SOS alert?',
        );
      }
    }

    // 2. Scan for blocked terms
    for (final word in _blockedKeywords) {
      if (text.contains(word)) {
        return const SafetyResult(
          isSafe: false,
          isEmergency: false,
          alertMessage: 'Your message contains content that violates our safety policy.',
        );
      }
    }

    return SafetyResult(isSafe: true, isEmergency: false, filteredText: input);
  }
}
