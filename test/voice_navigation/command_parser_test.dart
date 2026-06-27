import 'package:flutter_test/flutter_test.dart';

import 'package:accessibility_super_app/features/voice_navigation/domain/command_intent.dart';
import 'package:accessibility_super_app/features/voice_navigation/domain/command_parser.dart';

void main() {
  group('CommandParser Intent Matching Tests', () {
    late CommandParser parser;

    setUp(() {
      parser = CommandParser();
    });

    test('Verify basic English navigation command parsing', () {
      expect(parser.parse('open dashboard'), equals(CommandIntent.home));
      expect(parser.parse('Show my medications reminder list'), equals(CommandIntent.medications));
      expect(parser.parse('chat with robo helper assistant'), equals(CommandIntent.aiAssistant));
      expect(parser.parse('danger help emergency alert'), equals(CommandIntent.sos));
      expect(parser.parse('go back to previous screen'), equals(CommandIntent.goBack));
    });

    test('Verify basic Hindi navigation command parsing', () {
      expect(parser.parse('दवाई दिखाओ'), equals(CommandIntent.medications));
      expect(parser.parse('मुख्य होम स्क्रीन खोलो'), equals(CommandIntent.home));
      expect(parser.parse('आपातकाल आपातकालीन कॉल'), equals(CommandIntent.sos));
      expect(parser.parse('प्रोफाइल सेटिंग विकल्प'), equals(CommandIntent.settings));
      expect(parser.parse('वापस जाओ'), equals(CommandIntent.goBack));
    });

    test('Verify basic Malayalam navigation command parsing', () {
      expect(parser.parse('മരുന്ന് കാണിക്കുക'), equals(CommandIntent.medications));
      expect(parser.parse('പ്രധാന ഹോം ഡാഷ്ബോർഡ്'), equals(CommandIntent.home));
      expect(parser.parse('അപകടം അടിയന്തരാവസ്ഥ'), equals(CommandIntent.sos));
      expect(parser.parse('ക്രമീകരണങ്ങൾ'), equals(CommandIntent.settings));
      expect(parser.parse('തിരിച്ചു പോകുക'), equals(CommandIntent.goBack));
    });

    test('Verify custom user-defined command mapping matching precedence', () {
      final customParser = CommandParser(
        customCommands: {
          'open list': CommandIntent.settings, // Custom nickname mapping
        },
      );

      // Matches custom rule over standard dictionary mappings
      expect(customParser.parse('open list'), equals(CommandIntent.settings));
    });

    test('Verify unknown input resolves to unknown', () {
      expect(parser.parse('invalid random noise input'), equals(CommandIntent.unknown));
      expect(parser.parse(''), equals(CommandIntent.unknown));
    });
  });
}
