class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.progress,
  });
}

class AchievementService {
  static List<Achievement> calculateAchievements(Map<String, dynamic>? userImpact) {
    final int totalReports = (userImpact?['totalReports'] as num?)?.toInt() ?? 0;
    final int verifiedReports = (userImpact?['verifiedReports'] as num?)?.toInt() ?? 0;
    final double totalCarbon = (userImpact?['totalCarbonImpact'] as num?)?.toDouble() ?? 0.0;
    final double verifiedCarbon = (userImpact?['totalVerifiedCarbon'] as num?)?.toDouble() ?? 0.0;

    return [
      Achievement(
        id: 'first_report',
        title: 'First Reporter',
        description: 'Submit your first environmental report',
        icon: '🌱',
        isUnlocked: totalReports >= 1,
        progress: (totalReports / 1).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'active_scout',
        title: 'Active Scout',
        description: 'Submit 5 environmental reports',
        icon: '🔍',
        isUnlocked: totalReports >= 5,
        progress: (totalReports / 5).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'guardian',
        title: 'Eco Guardian',
        description: 'Submit 10 environmental reports',
        icon: '🛡️',
        isUnlocked: totalReports >= 10,
        progress: (totalReports / 10).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'first_cleanup',
        title: 'First Cleanup',
        description: 'Complete 1 verified cleanup action',
        icon: '🧹',
        isUnlocked: verifiedReports >= 1,
        progress: (verifiedReports / 1).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'cleanup_hero',
        title: 'Cleanup Hero',
        description: 'Complete 5 verified cleanups',
        icon: '⭐',
        isUnlocked: verifiedReports >= 5,
        progress: (verifiedReports / 5).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'carbon_saver',
        title: 'Carbon Saver',
        description: 'Divert 5kg of CO₂',
        icon: '🍃',
        isUnlocked: verifiedCarbon >= 5.0,
        progress: (verifiedCarbon / 5.0).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'climate_champion',
        title: 'Climate Champion',
        description: 'Divert 25kg of CO₂',
        icon: '🌍',
        isUnlocked: verifiedCarbon >= 25.0,
        progress: (verifiedCarbon / 25.0).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'earth_master',
        title: 'Earth Master',
        description: 'Divert 50kg of CO₂ and 10 cleanups',
        icon: '👑',
        isUnlocked: verifiedCarbon >= 50.0 && verifiedReports >= 10,
        progress: (((verifiedCarbon / 50.0) + (verifiedReports / 10.0)) / 2).clamp(0.0, 1.0),
      ),
    ];
  }
}
