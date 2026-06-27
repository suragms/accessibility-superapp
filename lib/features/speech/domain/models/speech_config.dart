enum VoiceGender {
  male,
  female,
}

/// Structural entity representing user speech configurations and preferences.
class SpeechConfig {
  final double speechRate;
  final double pitch;
  final String localeCode;
  final VoiceGender voiceGender;
  final bool noiseReductionEnabled;

  const SpeechConfig({
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.localeCode = 'en-US',
    this.voiceGender = VoiceGender.female,
    this.noiseReductionEnabled = false,
  });

  SpeechConfig copyWith({
    double? speechRate,
    double? pitch,
    String? localeCode,
    VoiceGender? voiceGender,
    bool? noiseReductionEnabled,
  }) {
    return SpeechConfig(
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      localeCode: localeCode ?? this.localeCode,
      voiceGender: voiceGender ?? this.voiceGender,
      noiseReductionEnabled: noiseReductionEnabled ?? this.noiseReductionEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speechRate': speechRate,
      'pitch': pitch,
      'localeCode': localeCode,
      'voiceGender': voiceGender.name,
      'noiseReductionEnabled': noiseReductionEnabled,
    };
  }

  factory SpeechConfig.fromJson(Map<String, dynamic> json) {
    return SpeechConfig(
      speechRate: (json['speechRate'] as num).toDouble(),
      pitch: (json['pitch'] as num).toDouble(),
      localeCode: json['localeCode'] as String,
      voiceGender: VoiceGender.values.byName(json['voiceGender'] as String),
      noiseReductionEnabled: json['noiseReductionEnabled'] as bool? ?? false,
    );
  }
}
