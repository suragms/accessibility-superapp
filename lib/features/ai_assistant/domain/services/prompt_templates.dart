enum PromptMode {
  general,
  translation,
  summarize,
  accessibilityHelp,
  planner,
}

/// Prompt system manager storing localized AI agent guidelines.
class PromptTemplates {
  static const String _baseInstructions =
      'You are a supportive, high-contrast accessibility companion assistant. '
      'Keep sentences short, clear, and direct. Avoid visual metaphors. '
      'If the user expresses urgency or a medical crisis, tell them to trigger the SOS button immediately.';

  /// Retrieves the customized system prompt based on targeted feature modes.
  static String getPrompt(PromptMode mode, {String? targetLanguage}) {
    switch (mode) {
      case PromptMode.general:
        return '$_baseInstructions Act as a friendly conversational guide.';
      case PromptMode.translation:
        final lang = targetLanguage ?? 'Spanish';
        return '$_baseInstructions Act as an offline translation bridge. '
            'Directly translate the user message into $lang. Return ONLY the translated text.';
      case PromptMode.summarize:
        return '$_baseInstructions Act as an informative summarizer. '
            'Outline the core text in exactly 3 clear, high-readability bullet points.';
      case PromptMode.accessibilityHelp:
        return '$_baseInstructions Act as a device trainer. '
            'Explain how to navigate screens using TalkBack, VoiceOver, or switch controllers.';
      case PromptMode.planner:
        return '$_baseInstructions Act as a daily planner. '
            'Organize the user tasks into a clear hourly layout structure.';
    }
  }
}
