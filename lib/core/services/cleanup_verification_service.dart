import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class CleanupVerificationService {
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
    try {
      final beforeBytes = await beforeImage.readAsBytes();
      final afterBytes = await afterImage.readAsBytes();
      final beforeBase64 = base64Encode(beforeBytes);
      final afterBase64 = base64Encode(afterBytes);

      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"
      );

      final response = await http.post(
        url,
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data["candidates"][0]["content"]["parts"][0]["text"];
        final result = _parseJson(text);
        final cleaned = result['cleaned'] as bool?;
        final confidence = result['confidence'] as double?;

        return (cleaned == true) && (confidence != null && confidence >= 0.7);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> _parseJson(String text) {
    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    return jsonDecode(cleaned);
  }
}
