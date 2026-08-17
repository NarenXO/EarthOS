/*
|--------------------------------------------------------------------------
| EarthOS
| File: app_config.dart
| Author: Naren
|--------------------------------------------------------------------------
| Centralized App Branding & Identity Configuration
|--------------------------------------------------------------------------
*/


class AppConfig {
  // ===============================
  // APP IDENTITY
  // ===============================
  static const String appName = "EarthOS";
  static const String aiName = "AXIS";
  static const String tagline =
      "The Operating System for Environmental Accountability";
  static const String poweredBy = "Powered by AXIS";
  static const String author = "Naren";

  // ===============================
  // TAB LABELS
  // ===============================
  static const String exploreTab = "Explore";
  static const String reportTab = "Report";
  static const String impactTab = "Impact";
  static const String profileTab = "Profile";

  // ===============================
  // VERSION INFO
  // ===============================
  static const String version = "1.0.0";

  // ===============================
  // API CONFIG
  // ===============================
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY');
  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';
  static const String openWeatherKey = String.fromEnvironment(
    'OPENWEATHER_KEY',
    defaultValue: 'a30e97b0c1d362a9e257fdcc2e363883',
  );
  static const String waqiToken = String.fromEnvironment(
    'WAQI_TOKEN',
    defaultValue: 'c5c973401d8da5472980d0792853b96c190d31a3',
  );

  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static const String groqTextEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
}
