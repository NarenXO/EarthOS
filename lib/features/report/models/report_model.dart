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
    };
  }
}
