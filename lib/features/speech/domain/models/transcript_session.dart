/// Structural entity representing a recorded transcription session.
class TranscriptSession {
  final String id;
  final DateTime timestamp;
  final List<String> textLines;

  const TranscriptSession({
    required this.id,
    required this.timestamp,
    required this.textLines,
  });

  String get fullText => textLines.join('\n');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'textLines': textLines,
    };
  }

  factory TranscriptSession.fromJson(Map<String, dynamic> json) {
    return TranscriptSession(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      textLines: List<String>.from(json['textLines'] as List<dynamic>),
    );
  }
}
