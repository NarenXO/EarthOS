import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class RecyclingRouteService {
  static Future<Map<String, dynamic>> findNearestFacility({
    required double lat,
    required double lng,
    required String wasteType,
  }) async {
    try {
      String amenity = 'recycling';
      if (wasteType.toLowerCase().contains('e-waste') || wasteType.toLowerCase().contains('electronic')) {
        amenity = 'waste_transfer_station';
      }

      final radius = 5000;
      final query = '''
[out:json][timeout:15];
(
  node["amenity"="$amenity"](around:$radius,$lat,$lng);
  node["recycling_type"="centre"](around:$radius,$lat,$lng);
  way["amenity"="$amenity"](around:$radius,$lat,$lng);
);
out center 10;
''';
      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await http.post(url, body: {'data': query}).timeout(const Duration(seconds: 20));
      
      print('Recycling route status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List;
        
        if (elements.isEmpty) {
          return {
            'found': false,
            'message': 'No recycling facilities found within 5km. Try expanding search.',
          };
        }
        
        double closestDist = double.infinity;
        Map<String, dynamic>? closest;
        
        for (var el in elements) {
          final elLat = (el['lat'] ?? el['center']?['lat'])?.toDouble();
          final elLng = (el['lon'] ?? el['center']?['lon'])?.toDouble();
          if (elLat == null || elLng == null) continue;
          
          final dist = _haversine(lat, lng, elLat, elLng);
          if (dist < closestDist) {
            closestDist = dist;
            closest = {
              'name': el['tags']?['name'] ?? 'Recycling Facility',
              'lat': elLat,
              'lng': elLng,
              'distance': dist,
              'operator': el['tags']?['operator'] ?? '',
            };
          }
        }
        
        return {
          'found': true,
          'facility': closest,
          'totalNearby': elements.length,
          'directionsUrl': 'https://www.google.com/maps/dir/?api=1&destination=${closest!['lat']},${closest['lng']}',
        };
      }
      return {'found': false, 'message': 'Search failed'};
    } catch (e) {
      print('Recycling route error: $e');
      return {'found': false, 'message': 'Error: $e'};
    }
  }

  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;
}
