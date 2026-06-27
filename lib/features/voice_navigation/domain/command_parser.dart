import 'command_intent.dart';

/// Offline-First Command Parser translating vocal utterances into navigation intents.
/// Supports English, Hindi, and Malayalam commands, plus runtime user-custom commands.
class CommandParser {
  final Map<String, CommandIntent> _customCommands;

  CommandParser({Map<String, CommandIntent>? customCommands})
      : _customCommands = customCommands ?? {};

  /// Localized dictionaries mapping keywords to corresponding intents.
  static const Map<String, List<String>> _englishMap = {
    'home': ['home', 'dashboard', 'start', 'main page'],
    'aiAssistant': ['assistant', 'ai', 'chat', 'bot', 'helper', 'robo'],
    'speechToText': ['speech', 'text', 'caption', 'transcribe', 'live captions', 'hearing assistant'],
    'medications': ['medication', 'medicine', 'meds', 'schedule', 'pill', 'reminders'],
    'caregiver': ['caregiver', 'connection', 'family', 'nurse', 'doctor', 'helper contact'],
    'settings': ['setting', 'profile', 'config', 'theme', 'accessibility'],
    'sos': ['sos', 'emergency', 'help', 'danger', 'alert', 'broadcast'],
    'goBack': ['back', 'go back', 'previous', 'return', 'close'],
  };

  static const Map<String, List<String>> _hindiMap = {
    'home': ['होम', 'मुख्य', 'डैशबोर्ड'],
    'aiAssistant': ['असिस्टेंट', 'सहायक', 'चैट', 'बॉट'],
    'speechToText': ['अनुवाद', 'स्पीच', 'कैप्शन', 'आवाज'],
    'medications': ['दवाई', 'दवा', 'मेडिसिन', 'परचा', 'याद दिलाओ'],
    'caregiver': ['केयरगिवर', 'नर्स', 'परिवार', 'डॉक्टर'],
    'settings': ['सेटिंग', 'विकल्प', 'प्रोफाइल'],
    'sos': ['बचाओ', 'आपातकाल', 'खतरा', 'मदद'],
    'goBack': ['पीछे', 'वापस'],
  };

  static const Map<String, List<String>> _malayalamMap = {
    'home': ['ഹോം', 'പ്രധാന', 'ഡാഷ്ബോർഡ്'],
    'aiAssistant': ['അസിസ്റ്റന്റ്', 'സഹായി', 'ചാറ്റ്', 'ബോട്ട്'],
    'speechToText': ['സംഭാഷണം', 'സ്പീച്ച്', 'ക്യാപ്ഷൻ'],
    'medications': ['മരുന്ന്', 'മെഡിക്കേഷൻ', 'ഗുളിക'],
    'caregiver': ['കെയർഗിവർ', 'ഡോക്ടർ', 'കുടുംബം'],
    'settings': ['ക്രമീകരണങ്ങൾ', 'സെറ്റിംഗ്സ്'],
    'sos': ['അടിയന്തരാവസ്ഥ', 'രക്ഷിക്കുക', 'അപകടം', 'സഹായം'],
    'goBack': ['തിരിച്ചു', 'പിന്നിലേക്ക്'],
  };

  /// Parses text input and resolves to a CommandIntent.
  CommandIntent parse(String input) {
    final text = input.trim().toLowerCase();
    if (text.isEmpty) return CommandIntent.unknown;

    // 1. Check custom commands first
    for (final entry in _customCommands.entries) {
      if (text.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Helper match checker
    CommandIntent? matchMap(Map<String, List<String>> localizedMap) {
      for (final entry in localizedMap.entries) {
        final key = entry.key;
        final phrases = entry.value;
        for (final phrase in phrases) {
          if (text.contains(phrase.toLowerCase())) {
            switch (key) {
              case 'home':
                return CommandIntent.home;
              case 'aiAssistant':
                return CommandIntent.aiAssistant;
              case 'speechToText':
                return CommandIntent.speechToText;
              case 'medications':
                return CommandIntent.medications;
              case 'caregiver':
                return CommandIntent.caregiver;
              case 'settings':
                return CommandIntent.settings;
              case 'sos':
                return CommandIntent.sos;
              case 'goBack':
                return CommandIntent.goBack;
            }
          }
        }
      }
      return null;
    }

    // 2. Scan English dictionary
    final enMatch = matchMap(_englishMap);
    if (enMatch != null) return enMatch;

    // 3. Scan Hindi dictionary
    final hiMatch = matchMap(_hindiMap);
    if (hiMatch != null) return hiMatch;

    // 4. Scan Malayalam dictionary
    final mlMatch = matchMap(_malayalamMap);
    if (mlMatch != null) return mlMatch;

    return CommandIntent.unknown;
  }
}
