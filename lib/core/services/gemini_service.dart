import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GeminiService {
  static const List<String> _models = [
    'gemini-flash-latest',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static Future<String> generate(String prompt) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      for (var model in _models) {
        try {
          final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
          print('GeminiService: try attempt=$attempt model=$model');
          
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': AppConfig.geminiApiKey,
            },
            body: jsonEncode({
              'contents': [{'parts': [{'text': prompt}]}],
              'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024}
            }),
          ).timeout(const Duration(seconds: 30));

          print('GeminiService: status=${response.statusCode} model=$model');
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return data['candidates'][0]['content']['parts'][0]['text'] as String;
          }
          
          if (response.statusCode == 503 || response.statusCode == 429) {
            print('GeminiService: overloaded, trying next model');
            continue;
          }
          
          print('GeminiService error: ${response.body}');
          return 'Error ${response.statusCode}';
        } catch (e) {
          print('GeminiService exception attempt=$attempt: $e');
          continue;
        }
      }
      
      if (attempt < 2) {
        final delay = Duration(seconds: 2 * (attempt + 1));
        print('GeminiService: waiting ${delay.inSeconds}s before retry');
        await Future.delayed(delay);
      }
    }
    
    return 'AI is temporarily unavailable due to high demand. Please try again in a minute.';
  }
}
