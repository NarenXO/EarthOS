import 'dart:convert';
import 'package:http/http.dart' as http;

class ForestService {
  Future<Map<String, dynamic>> fetchForestAlerts({
    required double lat,
    required double lng,
  }) async {
    try {
      // Calculate bounding box (±0.1 degrees around the point)
      final minLat = lat - 0.1;
      final maxLat = lat + 0.1;
      final minLng = lng - 0.1;
      final maxLng = lng + 0.1;

      // Global Forest Watch GLAD Alerts API endpoint
      // Using the public API for GLAD alerts
      final url = Uri.parse(
        'https://data-api.globalforestwatch.org/glad-alerts'
        '?min_lat=$minLat'
        '&max_lat=$maxLat'
        '&min_lon=$minLng'
        '&max_lon=$maxLng'
        '&period=2023-01-01,2024-12-31',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return _getEmptyData();
      }

      final data = jsonDecode(response.body);

      // Parse the response based on Global Forest Watch API structure
      final features = data['features'] as List<dynamic>? ?? [];
      
      int alertCount = features.length;
      int highConfidence = 0;
      int mediumConfidence = 0;
      int recentAlerts = 0;

      // Parse confidence levels and recent alerts
      for (final feature in features) {
        final properties = feature['properties'] as Map<String, dynamic>?;
        
        // Check confidence level (if available)
        final confidence = properties?['confidence'] as String?;
        if (confidence != null) {
          if (confidence.toLowerCase() == 'high') {
            highConfidence++;
          } else if (confidence.toLowerCase() == 'medium') {
            mediumConfidence++;
          }
        }

        // Check if alert is recent (last 30 days)
        final alertDate = properties?['alert_date'] as String?;
        if (alertDate != null) {
          final date = DateTime.tryParse(alertDate);
          if (date != null) {
            final daysSince = DateTime.now().difference(date).inDays;
            if (daysSince <= 30) {
              recentAlerts++;
            }
          }
        }
      }

      return {
        'alertCount': alertCount,
        'highConfidence': highConfidence,
        'mediumConfidence': mediumConfidence,
        'recentAlerts': recentAlerts,
      };
    } catch (e) {
      // Return empty data on any error
      return _getEmptyData();
    }
  }

  Map<String, dynamic> _getEmptyData() {
    return {
      'alertCount': 0,
      'highConfidence': 0,
      'mediumConfidence': 0,
      'recentAlerts': 0,
    };
  }
}
