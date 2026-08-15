import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AirQualityService {
  static Future<Map<String, dynamic>> fetchAQI(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.waqi.info/feed/geo:$lat;$lng/?token=${AppConfig.waqiToken}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      
      print('AQI status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          final aqi = data['data']['aqi'] ?? 0;
          final city = data['data']['city']['name'] ?? 'Unknown';
          final dominentPol = data['data']['dominantpol'] ?? '';
          return {
            'aqi': aqi,
            'city': city,
            'dominantPollutant': dominentPol,
            'category': _getCategory(aqi),
            'color': _getColor(aqi),
            'healthAdvice': _getAdvice(aqi),
          };
        }
      }
      return {'aqi': 0, 'category': 'Unknown', 'color': 0xFF888888};
    } catch (e) {
      print('AQI error: $e');
      return {'aqi': 0, 'category': 'Error', 'color': 0xFF888888};
    }
  }

  static String _getCategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  static int _getColor(int aqi) {
    if (aqi <= 50) return 0xFF00E400;
    if (aqi <= 100) return 0xFFFFFF00;
    if (aqi <= 150) return 0xFFFF7E00;
    if (aqi <= 200) return 0xFFFF0000;
    if (aqi <= 300) return 0xFF8F3F97;
    return 0xFF7E0023;
  }

  static String _getAdvice(int aqi) {
    if (aqi <= 50) return 'Air quality is good. Enjoy outdoor activities.';
    if (aqi <= 100) return 'Air is acceptable. Sensitive people should limit prolonged outdoor exertion.';
    if (aqi <= 150) return 'Sensitive groups should reduce outdoor activities.';
    if (aqi <= 200) return 'Everyone may begin to experience effects. Limit outdoor activities.';
    if (aqi <= 300) return 'Health alert. Avoid outdoor exertion.';
    return 'Emergency conditions. Stay indoors.';
  }
}
