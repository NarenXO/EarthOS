import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:earthos/core/config/app_config.dart';

class GeminiService {

  Future<String> generateText(String prompt) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${AppConfig.geminiApiKey}"
    );

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      return "AI service error (${response.statusCode}).";
    }
  }
}
