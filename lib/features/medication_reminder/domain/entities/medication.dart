import 'package:meta/meta.dart';

/// Immutable domain entity representing a Medication configured by the user or caregiver.
@immutable
class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String cronSchedule; // e.g. "0 8,20 * * *" representing twice daily (8 AM and 8 PM)
  final bool isActive;
  final DateTime createdAt;

  const Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.cronSchedule,
    this.isActive = true,
    required this.createdAt,
  });

  Medication copyWith({
    String? id,
    String? userId,
    String? name,
    String? dosage,
    String? cronSchedule,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      cronSchedule: cronSchedule ?? this.cronSchedule,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Medication &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          dosage == other.dosage &&
          cronSchedule == other.cronSchedule &&
          isActive == other.isActive &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      dosage.hashCode ^
      cronSchedule.hashCode ^
      isActive.hashCode ^
      createdAt.hashCode;
}

/// Status of the medication intake schedule.
enum LogStatus {
  taken,
  missed,
  snoozed,
}

/// Immutable domain entity tracking the execution logs of a medication schedule.
@immutable
class MedicationLog {
  final String id;
  final String medicationId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final LogStatus status;
  final bool isSynced;

  const MedicationLog({
    required this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
    this.isSynced = false,
  });

  MedicationLog copyWith({
    String? id,
    String? medicationId,
    DateTime? scheduledTime,
    DateTime? takenTime,
    LogStatus? status,
    bool? isSynced,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          medicationId == other.medicationId &&
          scheduledTime == other.scheduledTime &&
          takenTime == other.takenTime &&
          status == other.status &&
          isSynced == other.isSynced;

  @override
  int get hashCode =>
      id.hashCode ^
      medicationId.hashCode ^
      scheduledTime.hashCode ^
      takenTime.hashCode ^
      status.hashCode ^
      isSynced.hashCode;
}
