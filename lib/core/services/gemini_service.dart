import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GeminiService {
  static Future<String> generate(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.geminiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': AppConfig.geminiApiKey,
        },
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024}
        }),
      ).timeout(const Duration(seconds: 30));
      print('Gemini status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      }
      print('Gemini error: ${response.body}');
      return 'Error ${response.statusCode}';
    } catch (e) {
      print('Gemini exception: $e');
      return 'Error: $e';
    }
  }
}
