class TrendService {
  Future<Map<String, dynamic>> calculateTrends({
    required List<Map<String, dynamic>> reports,
    required List<Map<String, dynamic>> forestAlerts,
  }) async {
    final now = DateTime.now();
    
    // Weekly report trend (last 7 days vs previous 7 days)
    final last7Days = now.subtract(const Duration(days: 7));
    final previous7DaysStart = now.subtract(const Duration(days: 14));
    
    final reportsLast7Days = reports.where((r) {
      final createdAt = DateTime.parse(r['created_at'] as String);
      return createdAt.isAfter(last7Days);
    }).length;
    
    final reportsPrevious7Days = reports.where((r) {
      final createdAt = DateTime.parse(r['created_at'] as String);
      return createdAt.isAfter(previous7DaysStart) && createdAt.isBefore(last7Days);
    }).length;
    
    double weeklyReportChange = 0.0;
    if (reportsPrevious7Days > 0) {
      weeklyReportChange = ((reportsLast7Days - reportsPrevious7Days) / reportsPrevious7Days) * 100;
    }
    
    // Cleanup efficiency trend (last 30 days vs previous 30 days)
    final last30Days = now.subtract(const Duration(days: 30));
    final previous30DaysStart = now.subtract(const Duration(days: 60));
    
    final verifiedLast30Days = reports.where((r) {
      final createdAt = DateTime.parse(r['created_at'] as String);
      final verifiedAt = r['verified_at'] != null ? DateTime.parse(r['verified_at'] as String) : null;
      return verifiedAt != null && verifiedAt.isAfter(last30Days);
    }).length;
    
    final verifiedPrevious30Days = reports.where((r) {
      final createdAt = DateTime.parse(r['created_at'] as String);
      final verifiedAt = r['verified_at'] != null ? DateTime.parse(r['verified_at'] as String) : null;
      return verifiedAt != null && verifiedAt.isAfter(previous30DaysStart) && verifiedAt.isBefore(last30Days);
    }).length;
    
    double cleanupEfficiencyChange = 0.0;
    if (verifiedPrevious30Days > 0) {
      cleanupEfficiencyChange = ((verifiedLast30Days - verifiedPrevious30Days) / verifiedPrevious30Days) * 100;
    }
    
    // Forest alert trend (last 30 days vs previous 30 days)
    final forestAlertsLast30Days = forestAlerts.where((alert) {
      final alertDate = DateTime.parse(alert['alert_date'] as String);
      return alertDate.isAfter(last30Days);
    }).length;
    
    final forestAlertsPrevious30Days = forestAlerts.where((alert) {
      final alertDate = DateTime.parse(alert['alert_date'] as String);
      return alertDate.isAfter(previous30DaysStart) && alertDate.isBefore(last30Days);
    }).length;
    
    double forestTrendChange = 0.0;
    if (forestAlertsPrevious30Days > 0) {
      forestTrendChange = ((forestAlertsLast30Days - forestAlertsPrevious30Days) / forestAlertsPrevious30Days) * 100;
    }
    
    return {
      'weeklyReportChange': weeklyReportChange,
      'cleanupEfficiencyChange': cleanupEfficiencyChange,
      'forestTrendChange': forestTrendChange,
    };
  }

  String getTrendExplanation({
    required double weeklyReportChange,
    required double cleanupEfficiencyChange,
    required double forestTrendChange,
  }) {
    final reportTrend = weeklyReportChange >= 0 ? 'increasing' : 'decreasing';
    final cleanupTrend = cleanupEfficiencyChange >= 0 ? 'improving' : 'declining';
    final forestTrend = forestTrendChange >= 0 ? 'rising' : 'falling';
    
    return '''
📊 ENVIRONMENTAL TREND ANALYSIS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WASTE REPORTING TREND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Weekly change: ${weeklyReportChange.toStringAsFixed(1)}%
• Trend: $reportTrend
${weeklyReportChange > 10 ? '⚠️ Warning: Rapid increase in waste reports' : weeklyReportChange < -10 ? '✓ Positive: Waste reporting decreasing' : '• Stable reporting pattern'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CLEANUP EFFICIENCY TREND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Monthly change: ${cleanupEfficiencyChange.toStringAsFixed(1)}%
• Trend: $cleanupTrend
${cleanupEfficiencyChange > 10 ? '✓ Excellent: Cleanup efficiency improving' : cleanupEfficiencyChange < -10 ? '⚠️ Concern: Cleanup efficiency declining' : '• Stable cleanup rate'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FOREST ALERT TREND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Monthly change: ${forestTrendChange.toStringAsFixed(1)}%
• Trend: $forestTrend
${forestTrendChange > 10 ? '⚠️ Warning: Forest loss activity increasing' : forestTrendChange < -10 ? '✓ Positive: Forest loss decreasing' : '• Stable forest conditions'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OVERALL ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${cleanupEfficiencyChange > 0 && forestTrendChange < 0 ? '• Positive trajectory: Cleanups improving, forest loss declining' : cleanupEfficiencyChange < 0 && forestTrendChange > 0 ? '• Concerning trend: Cleanups declining, forest loss increasing' : '• Mixed trends: Monitor closely'}
''';
  }
}
