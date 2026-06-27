import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/speech_config.dart';
import '../../domain/models/transcript_session.dart';

/// Repository managing local cache of Speech settings and exported text transcripts.
class SpeechRepository {
  static const String _configFileName = 'speech_preferences.json';

  Future<File> _getFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, name));
  }

  /// Writes user configurations to JSON cache.
  Future<void> saveConfig(SpeechConfig config) async {
    try {
      final file = await _getFile(_configFileName);
      await file.writeAsString(json.encode(config.toJson()));
    } catch (e) {
      // Fail silently
    }
  }

  /// Reads user configurations. Returns default profile if none exists.
  Future<SpeechConfig> loadConfig() async {
    try {
      final file = await _getFile(_configFileName);
      if (!await file.exists()) return const SpeechConfig();

      final data = json.decode(await file.readAsString()) as Map<String, dynamic>;
      return SpeechConfig.fromJson(data);
    } catch (e) {
      return const SpeechConfig();
    }
  }

  /// Exports transcript sessions as high-contrast plain text records.
  Future<File> exportTranscript(TranscriptSession session) async {
    final dir = await getApplicationDocumentsDirectory();
    final name = 'transcript_session_${session.id}.txt';
    final file = File(p.join(dir.path, name));

    final StringBuffer buffer = StringBuffer()
      ..writeln('ACCESSIBILITY SUPERAPP SPEECH TRANSCRIPT')
      ..writeln('Session ID: ${session.id}')
      ..writeln('Date: ${session.timestamp.toLocal()}')
      ..writeln('========================================\n')
      ..writeln(session.fullText);

    return file.writeAsString(buffer.toString());
  }
}
