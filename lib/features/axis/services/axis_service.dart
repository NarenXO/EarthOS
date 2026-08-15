import 'package:earthos/core/services/risk_engine.dart';
import 'package:earthos/core/services/trend_service.dart';
import 'package:earthos/core/services/recommendation_engine.dart';
import 'package:earthos/core/services/gemini_service.dart';
import 'package:earthos/core/models/user_identity.dart';
import 'package:earthos/features/report/services/report_service.dart';
import 'package:earthos/features/axis/models/axis_response.dart';
import 'package:earthos/features/axis/services/system_context_service.dart';

class AxisService {
  final ReportService _reportService = ReportService();
  final SystemContextService _systemContextService = SystemContextService();
  final TrendService _trendService = TrendService();

  Future<AxisResponse> processMessage({
    required String message,
    required UserIdentity user,
  }) async {
    try {
      final lowerMessage = message.toLowerCase();
      final systemContext = await _systemContextService.fetchSystemContext(user.id);

      // Intent detection
      if (_containsAny(lowerMessage, ['report', 'waste', 'photo'])) {
        return await _handleReportIntent(message, user);
      }
      if (_containsAny(lowerMessage, ['impact', 'my stats', 'my carbon'])) {
        return await _handleImpactIntent(user);
      }
      if (_containsAny(lowerMessage, ['risk', 'danger'])) {
        return await _handleRiskIntent(systemContext);
      }
      if (_containsAny(lowerMessage, ['trend'])) {
        return await _handleTrendIntent(systemContext);
      }
      if (_containsAny(lowerMessage, ['recommend', 'suggest'])) {
        return await _handleRecommendIntent(systemContext);
      }
      if (_containsAny(lowerMessage, ['forest', 'trees', 'deforestation'])) {
        return await _handleForestIntent(systemContext);
      }
      if (_containsAny(lowerMessage, ['weekly', 'summary', 'week'])) {
        return await _handleWeeklyIntent(systemContext);
      }
      if (_containsAny(lowerMessage, ['event', 'cleanup event', 'meetup', 'community'])) {
        return await _handleEventIntent();
      }
      if (_containsAny(lowerMessage, ['explain', 'how', 'why', 'what is'])) {
        return await _handleExplanationIntent(message, systemContext);
      }

      // Default: conversational response with system context
      return await _handleConversationalIntent(message, user, systemContext);
    } catch (e) {
      print("AxisService error: $e");
      return AxisResponse(
        message: "I encountered an error processing your request. Please try again.",
        executedAction: false,
      );
    }
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  Future<AxisResponse> _handleReportIntent(String message, UserIdentity user) async {
    final response = await GeminiService.generate(
      "The user wants to report waste. Guide them on how to use the report feature in EarthOS. "
      "Explain they can take photos of waste, classify it, and submit reports. "
      "User message: $message",
    );
    return AxisResponse(message: response, executedAction: false);
  }

  Future<AxisResponse> _handleImpactIntent(UserIdentity user) async {
    final userImpact = await _reportService.fetchUserImpact(user.id);
    final globalImpact = await _reportService.fetchImpactStats();

    final response = '''
📊 YOUR ENVIRONMENTAL IMPACT

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Your Reports: ${userImpact['totalReports']}
Verified Cleanups: ${userImpact['verifiedReports']}
Total Carbon Diverted: ${userImpact['totalCarbonImpact'].toStringAsFixed(2)} kg CO₂e
Verified Carbon: ${userImpact['totalVerifiedCarbon'].toStringAsFixed(2)} kg CO₂e

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Global Impact:
Total Reports: ${globalImpact['totalReports']}
Verified Cleanups: ${globalImpact['verifiedReports']}
Total Carbon Diverted: ${globalImpact['totalCarbonImpact'].toStringAsFixed(2)} kg CO₂e
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    return AxisResponse(message: response, executedAction: true);
  }

  Future<AxisResponse> _handleRiskIntent(Map<String, dynamic> context) async {
    final userImpact = context['userImpact'] as Map<String, dynamic>;
    final nearbyOpenReports = context['nearbyOpenReports'] as int;
    final forestAlerts = context['forestAlerts'] as Map<String, dynamic>;
    final highForestAlerts = forestAlerts['highConfidence'] as int;

    final riskScore = RiskEngine.calculateRiskScore(
      nearbyOpenReports: nearbyOpenReports,
      sensitiveReports: userImpact['totalSensitiveReports'] as int? ?? 0,
      highForestAlerts: highForestAlerts,
      daysSinceLastCleanup: 0,
    );

    final explanation = RiskEngine.getRiskExplanation(
      score: riskScore,
      nearbyOpenReports: nearbyOpenReports,
      sensitiveReports: userImpact['totalSensitiveReports'] as int? ?? 0,
      highForestAlerts: highForestAlerts,
      daysSinceLastCleanup: 0,
    );

    return AxisResponse(message: explanation, executedAction: true);
  }

  Future<AxisResponse> _handleTrendIntent(Map<String, dynamic> context) async {
    final reports = await _reportService.fetchReports();
    final forestAlerts = context['forestAlerts'] as Map<String, dynamic>;

    final trends = await _trendService.calculateTrends(
      reports: reports.map((r) => r.toJson()).toList(),
      forestAlerts: [forestAlerts],
    );

    final explanation = _trendService.getTrendExplanation(
      weeklyReportChange: trends['weeklyReportChange'] as double,
      cleanupEfficiencyChange: trends['cleanupEfficiencyChange'] as double,
      forestTrendChange: trends['forestTrendChange'] as double,
    );

    return AxisResponse(message: explanation, executedAction: true);
  }

  Future<AxisResponse> _handleRecommendIntent(Map<String, dynamic> context) async {
    final nearbyOpenReports = context['nearbyOpenReports'] as int;
    final forestAlerts = context['forestAlerts'] as Map<String, dynamic>;
    final highForestAlerts = forestAlerts['highConfidence'] as int;
    final rank = context['rank'] as int;

    final trends = {'weeklyReportChange': 0.0};

    final recommendations = RecommendationEngine.generateRecommendations(
      riskScore: 0.0,
      trends: trends,
      nearbyOpenReports: nearbyOpenReports,
      forestHighConfidence: highForestAlerts,
      userRank: rank,
    );

    final formatted = RecommendationEngine.formatRecommendations(recommendations);
    return AxisResponse(message: formatted, executedAction: true);
  }

  Future<AxisResponse> _handleForestIntent(Map<String, dynamic> context) async {
    final forestAlerts = context['forestAlerts'] as Map<String, dynamic>;

    final response = '''
🌲 FOREST MONITORING

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Alerts: ${forestAlerts['alertCount']}
High Confidence: ${forestAlerts['highConfidence']}
Medium Confidence: ${forestAlerts['mediumConfidence']}
Recent Alerts (30 days): ${forestAlerts['recentAlerts']}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${forestAlerts['alertCount'] > 0 ? '⚠️ Forest loss activity detected in your region' : '✓ No significant forest alerts detected'}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    return AxisResponse(message: response, executedAction: true);
  }

  Future<AxisResponse> _handleWeeklyIntent(Map<String, dynamic> context) async {
    final userImpact = context['userImpact'] as Map<String, dynamic>;
    final globalImpact = context['globalImpact'] as Map<String, dynamic>;
    final rank = context['rank'] as int;

    final response = '''
📅 WEEKLY SUMMARY

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Your Progress:
• Reports Submitted: ${userImpact['totalReports']}
• Verified Cleanups: ${userImpact['verifiedReports']}
• Carbon Diverted: ${userImpact['totalCarbonImpact'].toStringAsFixed(2)} kg CO₂e
• Your Rank: #$rank

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Global Progress:
• Total Reports: ${globalImpact['totalReports']}
• Verified Cleanups: ${globalImpact['verifiedReports']}
• Total Carbon: ${globalImpact['totalCarbonImpact'].toStringAsFixed(2)} kg CO₂e
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Keep up the great work, ${context['userImpact']['createdBy'] ?? 'environmental champion'}!
''';
    return AxisResponse(message: response, executedAction: true);
  }

  Future<AxisResponse> _handleEventIntent() async {
    final events = await _reportService.fetchUpcomingEvents();

    if (events.isEmpty) {
      return AxisResponse(
        message: "📅 No upcoming cleanup events or meetups scheduled. Check back later!",
        executedAction: true,
      );
    }

    final buffer = StringBuffer();
    buffer.writeln("📅 UPCOMING EVENTS");
    buffer.writeln("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    for (final event in events) {
      buffer.writeln("• ${event.title ?? 'Event'}");
      if (event.eventDate != null) {
        buffer.writeln("  Date: ${event.eventDate}");
      }
      if (event.description != null) {
        buffer.writeln("  ${event.description}");
      }
      buffer.writeln("  Participants: ${event.participantsCount ?? 0}");
      buffer.writeln("");
    }

    return AxisResponse(message: buffer.toString(), executedAction: true);
  }

  Future<AxisResponse> _handleExplanationIntent(String message, Map<String, dynamic> context) async {
    final prompt = "You are EarthOS, an environmental AI assistant. Explain: $message";
    final response = await GeminiService.generate(prompt);
    return AxisResponse(message: response, executedAction: false);
  }

  Future<AxisResponse> _handleConversationalIntent(
    String message,
    UserIdentity user,
    Map<String, dynamic> context,
  ) async {
    final userImpact = context['userImpact'] as Map<String, dynamic>;
    final rank = context['rank'] as int;

    final prompt = '''
You are EarthOS, an AI assistant for environmental conservation and climate action.

User: ${user.name}
Your Rank: #$rank
Your Reports: ${userImpact['totalReports']}
Your Carbon Diverted: ${userImpact['totalCarbonImpact'].toStringAsFixed(2)} kg CO₂e

User message: $message

Provide a helpful, conversational response about environmental topics.
''';
    final response = await GeminiService.generate(prompt);
    return AxisResponse(message: response, executedAction: false);
  }
}
