import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GroqService {
  static Future<String> generate(String prompt) async {
    try {
      print('GroqService: calling ${AppConfig.groqTextModel}');
      final response = await http.post(
        Uri.parse(AppConfig.groqTextEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.groqApiKey}',
        },
        body: jsonEncode({
          'model': AppConfig.groqTextModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 30));

      print('GroqService: status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      print('GroqService error body: ${response.body}');
      return '';
    } catch (e) {
      print('GroqService exception: $e');
      return '';
    }
  }

  static Future<String> generateWithImage(String prompt, String base64Image) async {
    try {
      print('GroqService: calling vision ${AppConfig.groqVisionModel}');
      final response = await http.post(
        Uri.parse(AppConfig.groqTextEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.groqApiKey}',
        },
        body: jsonEncode({
          'model': AppConfig.groqVisionModel,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                }
              ]
            }
          ],
          'temperature': 0.1,
          'max_tokens': 512,
        }),
      ).timeout(const Duration(seconds: 45));

      print('GroqService vision: status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      print('GroqService vision error body: ${response.body}');
      return '';
    } catch (e) {
      print('GroqService vision exception: $e');
      return '';
    }
  }
}
