class Report {
  final String id;
  final String type;
  final String status;
  final String? photoBefore;
  final String? photoAfter;
  final String? aiClassification;
  final int? severity;
  final double? carbonEstimate;
  final bool? isSensitive;
  final bool? isEmergency;
  final String? emergencyType;
  final double? fakeScore;
  final bool? flagged;
  final double lat;
  final double lng;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? title;
  final String? description;
  final String? eventDate;
  final int? participantsCount;
  final String? eventType;
  final int? maxParticipants;
  final String? venue;
  final List<String>? participants;

  Report({
    required this.id,
    required this.type,
    required this.status,
    this.photoBefore,
    this.photoAfter,
    this.aiClassification,
    this.severity,
    this.carbonEstimate,
    this.isSensitive,
    this.isEmergency,
    this.emergencyType,
    this.fakeScore,
    this.flagged,
    required this.lat,
    required this.lng,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.verifiedAt,
    this.title,
    this.description,
    this.eventDate,
    this.participantsCount,
    this.eventType,
    this.maxParticipants,
    this.venue,
    this.participants,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      photoBefore: json['photo_before'] as String?,
      photoAfter: json['photo_after'] as String?,
      aiClassification: json['ai_classification'] as String?,
      severity: json['severity'] as int?,
      carbonEstimate: json['carbon_estimate'] as double?,
      isSensitive: json['is_sensitive'] as bool?,
      isEmergency: json['is_emergency'] as bool?,
      emergencyType: json['emergency_type'] as String?,
      fakeScore: json['fake_score'] as double?,
      flagged: json['flagged'] as bool?,
      lat: json['lat'] as double,
      lng: json['lng'] as double,
      createdBy: json['created_by'] as String,
      createdByName: json['created_by_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at'] as String) 
          : null,
      title: json['title'] as String?,
      description: json['description'] as String?,
      eventDate: json['event_date'] as String?,
      participantsCount: json['participants_count'] as int?,
      eventType: json['event_type'] as String?,
      maxParticipants: json['max_participants'] as int?,
      venue: json['venue'] as String?,
      participants: json['participants'] != null 
          ? (json['participants'] as List).map((e) => e as String).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'photo_before': photoBefore,
      'photo_after': photoAfter,
      'ai_classification': aiClassification,
      'severity': severity,
      'carbon_estimate': carbonEstimate,
      'is_sensitive': isSensitive,
      'is_emergency': isEmergency,
      'emergency_type': emergencyType,
      'fake_score': fakeScore,
      'flagged': flagged,
      'lat': lat,
      'lng': lng,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'created_at': createdAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
      'title': title,
      'description': description,
      'event_date': eventDate,
      'participants_count': participantsCount,
      'event_type': eventType,
      'max_participants': maxParticipants,
      'venue': venue,
      'participants': participants,
    };
  }
}
