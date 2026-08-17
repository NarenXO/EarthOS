import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class CleanupVerificationService {
  static const List<String> _models = [
    'gemini-flash-latest',
    'gemini-2.0-flash-exp',
    'gemini-1.5-flash-latest',
  ];

  Future<bool> verifyCleanup(File beforeImage, File afterImage) async {
    try {
      final result = await _geminiVerification(beforeImage, afterImage);
      return result;
    } catch (e) {
      print('Cleanup verification error: $e');
      return false;
    }
  }

  Future<bool> _geminiVerification(File beforeImage, File afterImage) async {
    final beforeBytes = await beforeImage.readAsBytes();
    final afterBytes = await afterImage.readAsBytes();
    final beforeBase64 = base64Encode(beforeBytes);
    final afterBase64 = base64Encode(afterBytes);

    for (var attempt = 0; attempt < 3; attempt++) {
      for (var model in _models) {
        try {
          final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
          print('CleanupVerificationService: try attempt=$attempt model=$model');
          
          final response = await http.post(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "x-goog-api-key": AppConfig.geminiApiKey,
            },
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {
                      "text": "Compare BEFORE and AFTER images. Has waste been removed? Return JSON with cleaned (bool) and confidence (0-1)."
                    },
                    {
                      "inlineData": {
                        "mimeType": "image/jpeg",
                        "data": beforeBase64
                      }
                    },
                    {
                      "inlineData": {
                        "mimeType": "image/jpeg",
                        "data": afterBase64
                      }
                    }
                  ]
                }
              ]
            }),
          ).timeout(const Duration(seconds: 45));

          print('CleanupVerificationService: status=${response.statusCode} model=$model');
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final text = data["candidates"][0]["content"]["parts"][0]["text"];
            final result = _parseJson(text);
            final cleaned = result['cleaned'] as bool?;
            final confidence = result['confidence'] as double?;

            return (cleaned == true) && (confidence != null && confidence >= 0.7);
          }
          
          if (response.statusCode == 503 || response.statusCode == 429) {
            print('CleanupVerificationService: overloaded, trying next model');
            continue;
          }
          
          print('CleanupVerificationService error: ${response.body}');
          return false;
        } catch (e) {
          print('CleanupVerificationService exception attempt=$attempt: $e');
          continue;
        }
      }
      
      if (attempt < 2) {
        final delay = Duration(seconds: 2 * (attempt + 1));
        print('CleanupVerificationService: waiting ${delay.inSeconds}s before retry');
        await Future.delayed(delay);
      }
    }
    
    return false;
  }

  Map<String, dynamic> _parseJson(String text) {
    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    return jsonDecode(cleaned);
  }
}
