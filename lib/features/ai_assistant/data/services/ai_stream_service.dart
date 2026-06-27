import 'dart:async';

/// Client service executing chunked streaming requests simulating remote LLM (Gemini) channels.
class AiStreamService {
  /// Resolves the user request and yields a stream of words simulating real-time LLM API streams.
  Stream<String> sendMessageStream(String prompt, String systemPrompt) async* {
    final lowerPrompt = prompt.toLowerCase();

    final List<String> responseWords;

    // Local smart intent mocks based on prompt keywords
    if (lowerPrompt.contains('translate') || lowerPrompt.contains('अनुवाद')) {
      responseWords = 'This text translates to: "Welcome to our accessibility application."'.split(' ');
    } else if (lowerPrompt.contains('summarize') || lowerPrompt.contains('संक्षेप')) {
      responseWords = [
        'Here is the summary:',
        '\n• First, keep track of security options.',
        '\n• Second, set up medications log entries.',
        '\n• Third, access live captioning services.'
      ];
    } else if (lowerPrompt.contains('accessibility') || lowerPrompt.contains('talkback')) {
      responseWords = 'You can browse any item easily by using a single tab click to traverse focus nodes.'.split(' ');
    } else if (lowerPrompt.contains('plan') || lowerPrompt.contains('planner')) {
      responseWords = [
        'Here is your task planner list:',
        '\n• 09:00 AM - Morning walk and exercise',
        '\n• 12:00 PM - Take doctor prescribed medications',
        '\n• 04:00 PM - Call caregivers update connection.'
      ];
    } else {
      responseWords = 'I am here to help you navigate and control your SuperApp safely. Feel free to ask anything!'.split(' ');
    }

    // Stream word-by-word with delay to emulate native streaming channels
    for (final word in responseWords) {
      await Future.delayed(const Duration(milliseconds: 120));
      yield '$word ';
    }
  }
}
