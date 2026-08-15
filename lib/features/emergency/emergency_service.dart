import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyService {
  static const List<String> emergencyTypes = [
    'Chemical Spill',
    'Medical Waste',
    'Toxic Fumes',
    'Fire Hazard',
    'Sewage Leak',
    'Radioactive Material',
    'Biohazard',
  ];

  final _supabase = Supabase.instance.client;

  Future<String> createEmergencyReport({
    required String userId,
    required String userName,
    required String emergencyType,
    required String description,
    required double lat,
    required double lng,
    String? photoUrl,
  }) async {
    try {
      final response = await _supabase.from('reports').insert({
        'type': 'dumping',
        'status': 'open',
        'is_emergency': true,
        'emergency_type': emergencyType,
        'severity': 5,
        'title': 'EMERGENCY: $emergencyType',
        'description': description,
        'lat': lat,
        'lng': lng,
        'created_by': userId,
        'created_by_name': userName,
        'photo_before': photoUrl,
        'ai_classification': 'emergency',
        'carbon_estimate': 20.0,
      }).select().single();

      print('EMERGENCY REPORT CREATED: id=${response['id']}, type=$emergencyType');
      return response['id'] as String;
    } catch (e) {
      print('Emergency report error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchActiveEmergencies() async {
    try {
      final data = await _supabase
          .from('reports')
          .select()
          .eq('is_emergency', true)
          .neq('status', 'verified')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Fetch emergencies error: $e');
      return [];
    }
  }
}
