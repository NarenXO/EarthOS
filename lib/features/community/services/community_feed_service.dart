import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityFeedService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchRecentActivity({int limit = 20}) async {
    try {
      final data = await _supabase
          .from('reports')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      
      final activities = <Map<String, dynamic>>[];
      for (var report in data) {
        final createdAt = DateTime.parse(report['created_at']);
        final ago = _timeAgo(createdAt);
        final type = report['type'] ?? 'report';
        final status = report['status'] ?? 'open';
        
        String action;
        String icon;
        if (type == 'cleanup_event') {
          action = 'organized a cleanup event';
          icon = '📅';
        } else if (status == 'verified') {
          action = 'verified a cleanup';
          icon = '✅';
        } else if (type == 'dumping') {
          action = 'reported waste';
          icon = '🗑️';
        } else {
          action = 'took action';
          icon = '🌱';
        }
        
        activities.add({
          'user': report['created_by_name'] ?? 'Anonymous',
          'action': action,
          'icon': icon,
          'ago': ago,
          'carbon': report['carbon_estimate'] ?? 0,
          'title': report['title'] ?? report['ai_classification'] ?? 'Environmental action',
        });
      }
      return activities;
    } catch (e) {
      print('Community feed error: $e');
      return [];
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Stream<List<Map<String, dynamic>>> subscribeToFeed() {
    return _supabase
        .from('reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(20)
        .map((data) {
          return data.map((r) => {
            'user': r['created_by_name'] ?? 'Anonymous',
            'title': r['title'] ?? r['ai_classification'] ?? 'Action',
            'type': r['type'],
            'status': r['status'],
            'carbon': r['carbon_estimate'] ?? 0,
            'createdAt': r['created_at'],
          }).toList();
        });
  }
}
