class RecommendationEngine {
  static List<String> generateRecommendations({
    required double riskScore,
    required Map<String, dynamic> trends,
    required int nearbyOpenReports,
    required int forestHighConfidence,
    required int userRank,
  }) {
    final recommendations = <String>[];

    if (riskScore > 60) {
      recommendations.add("High environmental risk detected. Immediate cleanup action recommended.");
    }

    if (nearbyOpenReports > 2) {
      recommendations.add("Multiple open dumps nearby. Consider organizing a cleanup event.");
    }

    if (trends["weeklyReportChange"] > 10) {
      recommendations.add("Waste reporting is increasing. Community awareness may be needed.");
    }

    if (forestHighConfidence > 5) {
      recommendations.add("Forest alerts rising. Monitor regional land-use changes.");
    }

    if (userRank <= 3) {
      recommendations.add("You are a top contributor. Lead a local environmental initiative.");
    }

    if (recommendations.isEmpty) {
      recommendations.add("Environmental indicators are stable. Continue monitoring and community engagement.");
    }

    return recommendations;
  }

  static String formatRecommendations(List<String> recommendations) {
    if (recommendations.isEmpty) {
      return "No specific recommendations at this time.";
    }

    final buffer = StringBuffer();
    buffer.writeln("💡 RECOMMENDED ACTIONS");
    buffer.writeln("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    
    for (int i = 0; i < recommendations.length; i++) {
      buffer.writeln("• ${recommendations[i]}");
    }
    
    return buffer.toString();
  }
}
