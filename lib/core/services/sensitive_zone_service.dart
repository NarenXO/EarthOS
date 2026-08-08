import 'dart:convert';
import 'package:http/http.dart' as http;

class SensitiveZoneService {
  final String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';

  Future<bool> isNearSensitiveZone({
    required double lat,
    required double lng,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=200'
        '&type=school|hospital'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);

      return (data['results'] as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
