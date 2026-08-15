import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class WeatherService {
  static Future<Map<String, dynamic>> fetchWeather(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&appid=${AppConfig.openWeatherKey}&units=metric',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      
      print('Weather status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = (data['main']['temp'] as num).toDouble();
        final condition = data['weather'][0]['main'] as String;
        final description = data['weather'][0]['description'] as String;
        final humidity = data['main']['humidity'] as int;
        final windSpeed = (data['wind']['speed'] as num).toDouble();
        
        return {
          'temp': temp,
          'condition': condition,
          'description': description,
          'humidity': humidity,
          'windSpeed': windSpeed,
          'cleanupRecommendation': _getRecommendation(temp, condition, windSpeed),
          'suitable': _isSuitable(temp, condition, windSpeed),
        };
      }
      return {'temp': 0.0, 'condition': 'Unknown', 'suitable': false};
    } catch (e) {
      print('Weather error: $e');
      return {'temp': 0.0, 'condition': 'Error', 'suitable': false};
    }
  }

  static String _getRecommendation(double temp, String condition, double wind) {
    if (condition.toLowerCase().contains('rain') || condition.toLowerCase().contains('storm')) {
      return 'Weather unsuitable for outdoor cleanup. Wait for clearer conditions.';
    }
    if (temp > 38) return 'Too hot for extended outdoor activity. Cleanup in early morning or evening.';
    if (temp < 5) return 'Very cold. Dress warmly if organizing cleanup.';
    if (wind > 15) return 'High winds may scatter waste. Consider indoor activities instead.';
    if (temp >= 18 && temp <= 30 && condition.toLowerCase().contains('clear')) {
      return 'Perfect weather for a cleanup! Consider organizing a community event.';
    }
    return 'Weather is acceptable for cleanup activities. Stay hydrated.';
  }

  static bool _isSuitable(double temp, String condition, double wind) {
    if (condition.toLowerCase().contains('rain')) return false;
    if (condition.toLowerCase().contains('storm')) return false;
    if (temp > 38 || temp < 5) return false;
    if (wind > 15) return false;
    return true;
  }
}
