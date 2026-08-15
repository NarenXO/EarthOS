import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:earthos/core/services/user_identity_service.dart';
import 'package:earthos/core/services/forest_service.dart';
import 'package:earthos/core/services/risk_engine.dart';
import 'package:earthos/core/services/trend_service.dart';
import 'package:earthos/core/services/recommendation_engine.dart';
import 'package:earthos/core/services/gemini_service.dart';
import 'package:earthos/core/models/user_identity.dart';
import 'package:earthos/features/report/services/report_service.dart';
import 'package:earthos/features/axis/models/axis_response.dart';
import 'package:earthos/features/axis/services/system_context_service.dart';
import 'package:earthos/core/config/app_config.dart';

class AxisService {

  final ReportService _reportService = ReportService();
  final UserIdentityService _userIdentityService = UserIdentityService();
  final ForestService _forestService = ForestService();
  final SystemContextService _systemContextService = SystemContextService();
  final TrendService _trendService = TrendService();
  final RecommendationEngine _recommendationEngine = RecommendationEngine();
  final GeminiService _geminiService = GeminiService();

  Future<AxisResponse> processMessage({
    required String message,
    required UserIdentity user,
  }) async {
    print("Gemini API Key: ${AppConfig.geminiApiKey}");

    if (AppConfig.geminiApiKey.isEmpty) {
      return AxisResponse(
        message: "Gemini API key is missing. Please run the app with --dart-define=GEMINI_API_KEY=YOUR_KEY",
        suggestedActions: [],
        context: [],
      );
    }

    try {
      final systemContext = await _systemContextService.getContext(user);
      final forestData = await _forestService.getNearbyForest(user.location);
      final trends = await _trendService.getTrends(user.location);
      final recommendations = await _recommendationEngine.getRecommendations(user);

      final prompt = _buildPrompt(
        message: message,
        user: user,
        systemContext: systemContext,
        forestData: forestData,
        trends: trends,
        recommendations: recommendations,
      );

      final aiResponse = await _geminiService.generateText(prompt);
      final parsedResponse = _parseResponse(aiResponse);

      return AxisResponse(
        message: parsedResponse['message'] as String,
        suggestedActions: parsedResponse['actions'] as List<String>,
        context: parsedResponse['context'] as List<String>,
      );
    } catch (e) {
      print("AxisService error: $e");
      return AxisResponse(
        message: "I encountered an error processing your request. Please try again.",
        suggestedActions: [],
        context: [],
      );
    }
  }

  String _buildPrompt({
    required String message,
    required UserIdentity user,
    required Map<String, dynamic> systemContext,
    required Map<String, dynamic> forestData,
    required Map<String, dynamic> trends,
    required List<String> recommendations,
  }) {
    return '''
You are EarthOS, an AI assistant for environmental conservation and climate action.

User Context:
- Name: ${user.name}
- Level: ${user.level}
- Total Cleanups: ${user.totalCleanups}
- Carbon Diverted: ${user.carbonDiverted} kg
- Location: ${user.location.latitude}, ${user.location.longitude}

System Context:
${jsonEncode(systemContext)}

Nearby Forest Data:
${jsonEncode(forestData)}

Environmental Trends:
${jsonEncode(trends)}

Recommendations:
${recommendations.join('\n')}

User Message: $message

Respond in JSON format:
{
  "message": "Your response message",
  "actions": ["action1", "action2", "action3"],
  "context": ["context1", "context2"]
}
''';
  }

  Map<String, dynamic> _parseResponse(String response) {
    try {
      final cleaned = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      print("Error parsing AI response: $e");
      return {
        'message': response,
        'actions': [],
        'context': [],
      };
    }
  }
}
