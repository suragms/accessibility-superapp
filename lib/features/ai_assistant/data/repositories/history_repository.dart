import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/chat_message.dart';

/// Offline-First repository reading and storing conversation logs using local file JSON serialization.
class HistoryRepository {
  static const String _fileName = 'ai_chat_history.json';

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, _fileName));
  }

  /// Saves the complete list of messages to the JSON file.
  Future<void> saveHistory(List<ChatMessage> messages) async {
    try {
      final file = await _getLocalFile();
      final jsonList = messages.map((m) => m.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      // Fail silently or log error
    }
  }

  /// Loads stored messages. Returns empty list if no logs exist.
  Future<List<ChatMessage>> loadHistory() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) return [];

      final contents = await file.readAsString();
      final jsonList = json.decode(contents) as List<dynamic>;

      return jsonList.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clears stored chat history files.
  Future<void> clearHistory() async {
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Fail silently
    }
  }
}
