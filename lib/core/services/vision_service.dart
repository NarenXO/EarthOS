import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class VisionService {
  static const List<String> _models = [
    'gemini-flash-latest',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static Future<Map<String, dynamic>> classifyWaste(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final b64 = base64Encode(bytes);
    
    for (var attempt = 0; attempt < 3; attempt++) {
      for (var model in _models) {
        try {
          final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
          print('VisionService: try attempt=$attempt model=$model');
          
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': AppConfig.geminiApiKey,
            },
            body: jsonEncode({
              'contents': [{
                'parts': [
                  {'inlineData': {'mimeType': 'image/jpeg', 'data': b64}},
                  {'text': 'Analyze waste. Return ONLY JSON no markdown: {"waste_type":"plastic|metal|organic|e-waste|mixed|unknown","severity":1,"description":"brief"} severity 1-5.'}
                ]
              }],
              'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 256}
            }),
          ).timeout(const Duration(seconds: 45));

          print('VisionService: status=${response.statusCode} model=$model');
          
          if (response.statusCode == 200) {
            final text = jsonDecode(response.body)['candidates'][0]['content']['parts'][0]['text'] as String;
            return jsonDecode(text.replaceAll('```json', '').replaceAll('```', '').trim()) as Map<String, dynamic>;
          }
          
          if (response.statusCode == 503 || response.statusCode == 429) {
            print('VisionService: overloaded, trying next model');
            continue;
          }
          
          print('VisionService error: ${response.body}');
          return {'waste_type': 'unknown', 'severity': 1, 'description': 'Failed'};
        } catch (e) {
          print('VisionService exception attempt=$attempt: $e');
          continue;
        }
      }
      
      if (attempt < 2) {
        final delay = Duration(seconds: 2 * (attempt + 1));
        print('VisionService: waiting ${delay.inSeconds}s before retry');
        await Future.delayed(delay);
      }
    }
    
    return {'waste_type': 'unknown', 'severity': 1, 'description': 'AI is temporarily unavailable. Please try again.'};
  }
}
