import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:earthos/core/config/app_config.dart';

class GeminiService {

  static const String _endpoint =
      "https://api.generativeai.google.com/v1/models/gemini-1.5-flash:generateContent";

  Future<String> generateText(String prompt) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AppConfig.geminiApiKey}",
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
      return "AI service error (${response.statusCode})";
    }
  }
}
