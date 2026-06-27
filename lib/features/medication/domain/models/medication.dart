/// Structural entity representing a user medication record.
class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String cronSchedule;
  final bool isActive;
  final String? doctorNotes;
  final String? voiceReminderPath;
  final DateTime createdAt;

  const MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.cronSchedule,
    this.isActive = true,
    this.doctorNotes,
    this.voiceReminderPath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'cronSchedule': cronSchedule,
      'isActive': isActive,
      'doctorNotes': doctorNotes,
      'voiceReminderPath': voiceReminderPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      cronSchedule: json['cronSchedule'] as String,
      isActive: json['isActive'] as bool? ?? true,
      doctorNotes: json['doctorNotes'] as String?,
      voiceReminderPath: json['voiceReminderPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
