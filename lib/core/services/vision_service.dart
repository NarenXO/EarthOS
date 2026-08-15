import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class VisionService {
  static Future<Map<String, dynamic>> classifyWaste(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final b64 = base64Encode(bytes);
      final response = await http.post(
        Uri.parse(AppConfig.geminiEndpoint),
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
      if (response.statusCode == 200) {
        final text = jsonDecode(response.body)['candidates'][0]['content']['parts'][0]['text'] as String;
        return jsonDecode(text.replaceAll('```json', '').replaceAll('```', '').trim()) as Map<String, dynamic>;
      }
      return {'waste_type': 'unknown', 'severity': 1, 'description': 'Failed'};
    } catch (e) {
      return {'waste_type': 'unknown', 'severity': 1, 'description': 'Error: $e'};
    }
  }
}
