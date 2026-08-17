import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GroqService {
  static const List<String> _textModels = [
    'openai/gpt-oss-120b',
    'openai/gpt-oss-20b',
    'groq/compound',
    'groq/compound-mini',
    'qwen/qwen3.6-27b',
  ];
  
  static const List<String> _visionModels = [
    'qwen/qwen3.6-27b',
  ];

  static Future<String> generate(String prompt) async {
    for (var model in _textModels) {
      try {
        print('GroqService: try model=$model');
        final response = await http.post(
          Uri.parse(AppConfig.groqTextEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConfig.groqApiKey}',
          },
          body: jsonEncode({
            'model': model,
            'messages': [{'role': 'user', 'content': prompt}],
            'temperature': 0.7,
            'max_tokens': 1024,
          }),
        ).timeout(const Duration(seconds: 30));

        print('GroqService: status=${response.statusCode} model=$model');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'] as String;
        }
        
        if (response.statusCode == 404) {
          print('GroqService: model deprecated, trying next');
          continue;
        }
        
        print('GroqService error body: ${response.body}');
      } catch (e) {
        print('GroqService exception: $e');
        continue;
      }
    }
    return '';
  }

  static Future<String> generateWithImage(String prompt, String base64Image) async {
    for (var model in _visionModels) {
      try {
        print('GroqService vision: try model=$model');
        final response = await http.post(
          Uri.parse(AppConfig.groqTextEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConfig.groqApiKey}',
          },
          body: jsonEncode({
            'model': model,
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
        
        if (response.statusCode == 404) {
          print('GroqService vision: model deprecated, trying next');
          continue;
        }
        
        print('GroqService vision error: ${response.body}');
      } catch (e) {
        print('GroqService vision exception: $e');
        continue;
      }
    }
    return '';
  }
}
