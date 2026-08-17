import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'groq_service.dart';

class GeminiService {
  static const List<String> _geminiModels = [
    'gemini-flash-latest',
    'gemini-flash-lite-latest',
    'gemini-pro-latest',
  ];

  static Future<String> generate(String prompt) async {
    // Try Groq first (faster, more reliable)
    print('AI: trying Groq primary');
    final groqResult = await GroqService.generate(prompt);
    if (groqResult.isNotEmpty) {
      print('AI: Groq succeeded');
      return groqResult;
    }
    
    print('AI: Groq failed, falling back to Gemini');
    
    // Fallback to Gemini with model rotation
    for (var attempt = 0; attempt < 2; attempt++) {
      for (var model in _geminiModels) {
        try {
          final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
          print('GeminiService: try model=$model');

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
          
          if (response.statusCode == 404 || response.statusCode == 503) {
            continue;
          }
          
          print('GeminiService error: ${response.body}');
        } catch (e) {
          print('GeminiService exception: $e');
          continue;
        }
      }
      if (attempt < 1) await Future.delayed(const Duration(seconds: 2));
    }
    
    return 'AI service is temporarily unavailable. Please try again in a moment.';
  }
}
