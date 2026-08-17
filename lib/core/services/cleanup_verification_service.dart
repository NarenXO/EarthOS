import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'groq_service.dart';

class CleanupVerificationService {
  Future<bool> verifyCleanup(File beforeImage, File afterImage) async {
    try {
      final result = await _hybridVerification(beforeImage, afterImage);
      return result;
    } catch (e) {
      print('Cleanup verification error: $e');
      return false;
    }
  }

  Future<bool> _hybridVerification(File beforeImage, File afterImage) async {
    final beforeBytes = await beforeImage.readAsBytes();
    final afterBytes = await afterImage.readAsBytes();
    final beforeBase64 = base64Encode(beforeBytes);
    final afterBase64 = base64Encode(afterBytes);

    final prompt = 'Compare BEFORE and AFTER images. Has waste been removed? Return JSON with cleaned (bool) and confidence (0-1).';

    // Try Groq Vision first
    print('CleanupVerification: trying Groq');
    try {
      final groqResult = await GroqService.generateWithImage(prompt, beforeBase64);
      if (groqResult.isNotEmpty) {
        final result = _parseJson(groqResult);
        final cleaned = result['cleaned'] as bool?;
        final confidence = result['confidence'] as double?;
        if (cleaned == true && confidence != null && confidence >= 0.7) {
          print('CleanupVerification: Groq succeeded');
          return true;
        }
      }
    } catch (e) {
      print('CleanupVerification: Groq failed: $e');
    }

    print('CleanupVerification: Groq failed, trying Gemini');

    // Fallback to Gemini Vision
    const geminiModels = ['gemini-flash-latest', 'gemini-flash-lite-latest'];
    for (var model in geminiModels) {
      try {
        final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
        print('CleanupVerificationService: try model=$model');
        
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
                    "text": prompt
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
      } catch (e) {
        print('CleanupVerificationService exception: $e');
        continue;
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
