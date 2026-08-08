import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'reports';

  Future<void> createReport({
    required String type,
    required double lat,
    required double lng,
    required String createdBy,
    required String createdByName,
    String? photoBefore,
    String? aiClassification,
    int? severity,
    double? carbonEstimate,
  }) async {
    await _supabase.from(_tableName).insert({
      'type': type,
      'lat': lat,
      'lng': lng,
      'created_by': createdBy,
      'created_by_name': createdByName,
      if (photoBefore != null) 'photo_before': photoBefore,
      if (aiClassification != null) 'ai_classification': aiClassification,
      if (severity != null) 'severity': severity,
      if (carbonEstimate != null) 'carbon_estimate': carbonEstimate,
    });
  }

  Future<List<Report>> fetchReports() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => Report.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Stream<List<Report>> streamReports() {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((event) => event
            .map((json) => Report.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  Future<void> verifyReport({
    required String reportId,
    required String photoAfter,
  }) async {
    await _supabase.from(_tableName).update({
      'status': 'verified',
      'photo_after': photoAfter,
      'verified_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }
}
