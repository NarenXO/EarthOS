class RiskEngine {
  static double calculateRiskScore({
    required int nearbyOpenReports,
    required int sensitiveReports,
    required int highForestAlerts,
    required int daysSinceLastCleanup,
  }) {
    double score = 0;

    score += nearbyOpenReports * 10;
    score += sensitiveReports * 8;
    score += highForestAlerts * 5;
    score += daysSinceLastCleanup * 2;

    if (score > 100) score = 100;

    return score;
  }

  static String getRiskStatus(double score) {
    if (score <= 30) return 'Low';
    if (score <= 60) return 'Moderate';
    return 'High';
  }

  static String getRiskExplanation({
    required double score,
    required int nearbyOpenReports,
    required int sensitiveReports,
    required int highForestAlerts,
    required int daysSinceLastCleanup,
  }) {
    final status = getRiskStatus(score);
    
    String contributingFactors = '';
    if (nearbyOpenReports > 0) {
      contributingFactors += '• $nearbyOpenReports open cleanup reports nearby\n';
    }
    if (sensitiveReports > 0) {
      contributingFactors += '• $sensitiveReports reports in sensitive zones\n';
    }
    if (highForestAlerts > 0) {
      contributingFactors += '• $highForestAlerts high-confidence forest alerts\n';
    }
    if (daysSinceLastCleanup > 7) {
      contributingFactors += '• $daysSinceLastCleanup days since last cleanup\n';
    }

    if (contributingFactors.isEmpty) {
      contributingFactors = '• No significant risk factors detected\n';
    }

    String recommendation = '';
    if (status == 'Low') {
      recommendation = 'Continue monitoring the area. Environmental conditions are stable.';
    } else if (status == 'Moderate') {
      recommendation = 'Consider addressing nearby cleanup reports and monitoring forest activity.';
    } else {
      recommendation = 'Immediate action recommended. Address open reports and stay alert to environmental changes.';
    }

    return '''
Environmental Risk Index: ${score.toStringAsFixed(0)}/100
Status: $status

Contributing Factors:
$contributingFactors
Recommendation:
$recommendation
''';
  }
}
