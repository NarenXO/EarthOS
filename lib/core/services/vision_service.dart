import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'groq_service.dart';

class VisionService {
  static Future<Map<String, dynamic>> classifyWaste(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final b64 = base64Encode(bytes);
      
      final prompt = 'Analyze this image for environmental waste. Return ONLY valid JSON no markdown, no code fences: {"waste_type":"plastic|metal|organic|e-waste|mixed|unknown","severity":1,"description":"brief description"} severity is integer 1-5.';
      
      // Try Groq Vision first
      print('Vision: trying Groq');
      final groqResult = await GroqService.generateWithImage(prompt, b64);
      if (groqResult.isNotEmpty) {
        try {
          final cleaned = groqResult.replaceAll('```json', '').replaceAll('```', '').trim();
          final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
          print('Vision: Groq succeeded');
          return parsed;
        } catch (e) {
          print('Vision: Groq JSON parse failed: $e');
        }
      }
      
      print('Vision: Groq failed, trying Gemini');
      
      // Fallback to Gemini Vision
      const geminiModels = ['gemini-flash-latest', 'gemini-flash-lite-latest'];
      for (var model in geminiModels) {
        try {
          final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
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
                  {'text': prompt}
                ]
              }],
              'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 256}
            }),
          ).timeout(const Duration(seconds: 45));

          if (response.statusCode == 200) {
            final text = jsonDecode(response.body)['candidates'][0]['content']['parts'][0]['text'] as String;
            return jsonDecode(text.replaceAll('```json', '').replaceAll('```', '').trim()) as Map<String, dynamic>;
          }
        } catch (_) { continue; }
      }
      
      return {'waste_type': 'unknown', 'severity': 1, 'description': 'Analysis failed'};
    } catch (e) {
      print('VisionService exception: $e');
      return {'waste_type': 'unknown', 'severity': 1, 'description': 'Error: $e'};
    }
  }
}
