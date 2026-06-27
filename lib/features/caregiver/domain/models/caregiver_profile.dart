/// Representation of a caregiver activity event for the timeline list.
class CaregiverActivityEvent {
  final String id;
  final DateTime timestamp;
  final String title;
  final String description;
  final String type; // 'MEDICATION', 'BATTERY', 'SOS', 'LOCATION'

  const CaregiverActivityEvent({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.description,
    required this.type,
  });
}

/// Representation of a Caregiver Profile mapping linked caregiver details and privacy consents.
class CaregiverProfile {
  final String caregiverId;
  final String name;
  final String phone;
  final String? email;
  final String status; // 'PENDING', 'ACTIVE', 'REVOKED'
  
  // Consents
  final bool shareGps;
  final bool shareMeds;
  final bool shareBattery;
  final bool shareSosHistory;

  const CaregiverProfile({
    required this.caregiverId,
    required this.name,
    required this.phone,
    this.email,
    required this.status,
    required this.shareGps,
    required this.shareMeds,
    required this.shareBattery,
    required this.shareSosHistory,
  });

  CaregiverProfile copyWith({
    bool? shareGps,
    bool? shareMeds,
    bool? shareBattery,
    bool? shareSosHistory,
  }) {
    return CaregiverProfile(
      caregiverId: caregiverId,
      name: name,
      phone: phone,
      email: email,
      status: status,
      shareGps: shareGps ?? this.shareGps,
      shareMeds: shareMeds ?? this.shareMeds,
      shareBattery: shareBattery ?? this.shareBattery,
      shareSosHistory: shareSosHistory ?? this.shareSosHistory,
    );
  }
}
