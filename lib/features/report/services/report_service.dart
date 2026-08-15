import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:earthos/features/report/models/report_model.dart';
import 'package:earthos/core/services/carbon_engine.dart';
import 'package:earthos/features/streak/streak_service.dart';

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
    final double computedCarbon = carbonEstimate ??
        CarbonEngine.calculateImpact(
          wasteType: type,
          severity: severity ?? 1,
        );

    print('Report created: type=$type severity=$severity carbon=$computedCarbon');

    await _supabase.from(_tableName).insert({
      'type': type,
      'lat': lat,
      'lng': lng,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'carbon_estimate': computedCarbon,
      if (photoBefore != null) 'photo_before': photoBefore,
      if (aiClassification != null) 'ai_classification': aiClassification,
      if (severity != null) 'severity': severity,
      if (isSensitive != null) 'is_sensitive': isSensitive,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (eventDate != null) 'event_date': eventDate,
      if (type == 'cleanup_event') 'participants_count': 0,
    });

    StreakService.updateStreak();
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

  Future<bool> verifyReport({
    required String reportId,
    required String photoAfter,
  }) async {
    try {
      print('Cleanup: updating report to verified');
      await _supabase.from(_tableName).update({
        'status': 'verified',
        'photo_after': photoAfter,
        'verified_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);
      return true;
    } catch (e) {
      print('Error updating report verification: $e');
      return false;
    }
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

    print('Impact stats: reports=$totalReports, verified=$verifiedReports, carbon=$totalCarbonImpact');

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

    print('Leaderboard fetch: total verified reports=${verifiedReports.length}');
    print('Leaderboard: grouped users=${userMap.length}');
    print('Leaderboard entries: $leaderboard');

    return leaderboard;
  }

  Future<void> joinEvent(String eventId) async {
    final current = await _supabase
        .from(_tableName)
        .select('participants_count')
        .eq('id', eventId)
        .single();

    final count = current['participants_count'] ?? 0;

    await _supabase
        .from(_tableName)
        .update({'participants_count': count + 1})
        .eq('id', eventId);
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
    try {
      await _supabase.rpc(
        'append_participant',
        params: {
          'event_id': eventId,
          'user_name': userName,
        },
      );
    } catch (e) {
      final current = await _supabase
          .from(_tableName)
          .select('participants_count')
          .eq('id', eventId)
          .single();

      final count = current['participants_count'] ?? 0;

      await _supabase
          .from(_tableName)
          .update({'participants_count': count + 1})
          .eq('id', eventId);
    }
  }

  Future<List<Map<String, dynamic>>> fetchTransformations() async {
    try {
      final data = await _supabase
          .from(_tableName)
          .select()
          .eq('status', 'verified')
          .not('photo_before', 'is', null)
          .not('photo_after', 'is', null)
          .order('verified_at', ascending: false)
          .limit(30);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Transformations error: $e');
      return [];
    }
  }

  Future<void> signUpAsVolunteer({
    required String eventId,
    required String userId,
    required String userName,
    required String role,
  }) async {
    try {
      await _supabase.from('volunteer_signups').insert({
        'event_id': eventId,
        'user_id': userId,
        'user_name': userName,
        'role': role,
      });
      print('Volunteer signed up: $userName as $role');
    } catch (e) {
      print('Volunteer signup error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchVolunteers(String eventId) async {
    try {
      final data = await _supabase
          .from('volunteer_signups')
          .select()
          .eq('event_id', eventId);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Fetch volunteers error: $e');
      return [];
    }
  }
}
