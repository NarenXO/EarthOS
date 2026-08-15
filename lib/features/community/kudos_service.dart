import 'package:supabase_flutter/supabase_flutter.dart';

class KudosService {
  final _supabase = Supabase.instance.client;

  Future<void> sendKudos({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    String? message,
  }) async {
    try {
      await _supabase.from('kudos').insert({
        'from_user_id': fromUserId,
        'from_user_name': fromUserName,
        'to_user_id': toUserId,
        'to_user_name': toUserName,
        'message': message ?? 'Thanks for your environmental impact!',
      });
      print('Kudos sent from $fromUserName to $toUserName');
    } catch (e) {
      print('Kudos send error: $e');
      rethrow;
    }
  }

  Future<int> getKudosReceived(String userId) async {
    try {
      final data = await _supabase
          .from('kudos')
          .select('id')
          .eq('to_user_id', userId);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getKudosMessages(String userId) async {
    try {
      final data = await _supabase
          .from('kudos')
          .select()
          .eq('to_user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }
}
