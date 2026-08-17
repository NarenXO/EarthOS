import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:earthos/core/config/app_config.dart';

class FakeReportDetectionService {
  static const List<String> _models = [
    'gemini-flash-latest',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static Future<Map<String, dynamic>> analyzePhoto(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final b64 = base64Encode(bytes);
    
    for (var attempt = 0; attempt < 3; attempt++) {
      for (var model in _models) {
        try {
          final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
          print('FakeReportDetectionService: try attempt=$attempt model=$model');
          
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
                  {'text': '''
Analyze this image and determine if it is a genuine photo of environmental waste or a fake/staged/downloaded image.

Consider:
- Is it a real-world photo (not a screenshot or downloaded image)?
- Are the shadows and lighting consistent?
- Does it look like actual outdoor/street environment?
- Signs of manipulation, watermarks, or stock photo style?
- Random unrelated subjects (people, pets, objects that aren't waste)?

Return ONLY JSON no markdown:
{"is_genuine": true/false, "confidence": 0.0-1.0, "reason": "brief explanation"}
'''}
                ]
              }],
              'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 256}
            }),
          ).timeout(const Duration(seconds: 30));

          print('FakeReportDetectionService: status=${response.statusCode} model=$model');
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
            final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
            final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
            
            final isGenuine = parsed['is_genuine'] as bool? ?? true;
            final confidence = (parsed['confidence'] as num?)?.toDouble() ?? 0.5;
            final reason = parsed['reason'] as String? ?? '';
            
            final fakeScore = isGenuine ? 0.0 : confidence;
            final flagged = !isGenuine && confidence >= 0.7;
            
            return {
              'isGenuine': isGenuine,
              'confidence': confidence,
              'reason': reason,
              'fakeScore': fakeScore,
              'flagged': flagged,
            };
          }
          
          if (response.statusCode == 503 || response.statusCode == 429) {
            print('FakeReportDetectionService: overloaded, trying next model');
            continue;
          }
          
          print('FakeReportDetectionService error: ${response.body}');
          return {'isGenuine': true, 'confidence': 0.5, 'reason': 'Analysis failed', 'fakeScore': 0.0, 'flagged': false};
        } catch (e) {
          print('FakeReportDetectionService exception attempt=$attempt: $e');
          continue;
        }
      }
      
      if (attempt < 2) {
        final delay = Duration(seconds: 2 * (attempt + 1));
        print('FakeReportDetectionService: waiting ${delay.inSeconds}s before retry');
        await Future.delayed(delay);
      }
    }
    
    return {'isGenuine': true, 'confidence': 0.5, 'reason': 'AI temporarily unavailable', 'fakeScore': 0.0, 'flagged': false};
  }
}
