import 'dart:convert';
import 'package:http/http.dart' as http;

class WaterBodyService {
  static Future<Map<String, dynamic>> checkNearbyWater(double lat, double lng) async {
    try {
      final radius = 500;
      final query = '''
[out:json][timeout:15];
(
  way["natural"="water"](around:$radius,$lat,$lng);
  way["waterway"](around:$radius,$lat,$lng);
  relation["natural"="water"](around:$radius,$lat,$lng);
);
out center;
''';
      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await http.post(url, body: {'data': query}).timeout(const Duration(seconds: 20));
      
      print('WaterBody status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List;
        final bodies = <Map<String, dynamic>>[];
        
        for (var el in elements) {
          final tags = el['tags'] ?? {};
          final name = tags['name'] ?? tags['waterway'] ?? tags['natural'] ?? 'Water body';
          final type = tags['natural'] ?? tags['waterway'] ?? 'unknown';
          bodies.add({'name': name, 'type': type});
        }
        
        return {
          'nearby': bodies.length,
          'bodies': bodies.take(5).toList(),
          'atRisk': bodies.isNotEmpty,
        };
      }
      return {'nearby': 0, 'bodies': [], 'atRisk': false};
    } catch (e) {
      print('WaterBody error: $e');
      return {'nearby': 0, 'bodies': [], 'atRisk': false};
    }
  }
}
