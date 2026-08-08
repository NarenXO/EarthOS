import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:earthos/features/report/models/report_model.dart';

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
    bool? isSensitive,
    String? title,
    String? description,
    String? eventDate,
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
      if (isSensitive != null) 'is_sensitive': isSensitive,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (eventDate != null) 'event_date': eventDate,
      if (type == 'cleanup_event') 'participants_count': 0,
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

  Future<Map<String, dynamic>> fetchImpactStats() async {
    final reports = await fetchReports();

    final totalReports = reports.length;
    final verifiedReports = reports.where((r) => r.status == 'verified').length;
    final totalCarbonImpact = reports.fold<double>(
      0.0,
      (sum, report) => sum + (report.carbonEstimate ?? 0.0),
    );
    final totalSensitiveReports = reports.where((r) => r.isSensitive == true).length;

    return {
      'totalReports': totalReports,
      'verifiedReports': verifiedReports,
      'totalCarbonImpact': totalCarbonImpact,
      'totalSensitiveReports': totalSensitiveReports,
    };
  }

  Future<Map<String, dynamic>> fetchUserImpact(String userId) async {
    final allReports = await fetchReports();
    final userReports = allReports.where((r) => r.createdBy == userId).toList();

    final totalReports = userReports.length;
    final verifiedReports = userReports.where((r) => r.status == 'verified').length;
    final totalCarbonImpact = userReports.fold<double>(
      0.0,
      (sum, report) => sum + (report.carbonEstimate ?? 0.0),
    );
    final totalVerifiedCarbon = userReports
        .where((r) => r.status == 'verified')
        .fold<double>(
          0.0,
          (sum, report) => sum + (report.carbonEstimate ?? 0.0),
        );

    return {
      'totalReports': totalReports,
      'verifiedReports': verifiedReports,
      'totalCarbonImpact': totalCarbonImpact,
      'totalVerifiedCarbon': totalVerifiedCarbon,
    };
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    final allReports = await fetchReports();
    final verifiedReports = allReports.where((r) => r.status == 'verified').toList();

    final Map<String, Map<String, dynamic>> userMap = {};

    for (final report in verifiedReports) {
      final userId = report.createdBy;
      final userName = report.createdByName;

      if (!userMap.containsKey(userId)) {
        userMap[userId] = {
          'userId': userId,
          'userName': userName,
          'carbonDiverted': 0.0,
          'verifiedCount': 0,
        };
      }

      userMap[userId]!['carbonDiverted'] = 
          (userMap[userId]!['carbonDiverted'] as double) + (report.carbonEstimate ?? 0.0);
      userMap[userId]!['verifiedCount'] = 
          (userMap[userId]!['verifiedCount'] as int) + 1;
    }

    final leaderboard = userMap.values.toList();
    leaderboard.sort((a, b) => 
        (b['carbonDiverted'] as double).compareTo(a['carbonDiverted'] as double));

    return leaderboard;
  }

  Future<void> joinEvent(String eventId) async {
    await _supabase.rpc('increment_participants', params: {'event_id': eventId});
  }

  Future<List<Report>> fetchUpcomingEvents() async {
    final now = DateTime.now().toIso8601String();
    final response = await _supabase
        .from(_tableName)
        .select()
        .or('type.eq.cleanup_event,type.eq.meetup')
        .gte('event_date', now)
        .order('event_date', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Report.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> joinEventWithName(String eventId, String userName) async {
    // Try to append to participants array first
    try {
      await _supabase.rpc(
        'append_participant',
        params: {
          'event_id': eventId,
          'user_name': userName,
        },
      );
    } catch (e) {
      // Fallback to incrementing participants_count
      await _supabase.from(_tableName).update({
        'participants_count': _supabase.raw('participants_count + 1'),
      }).eq('id', eventId);
    }
  }
}
