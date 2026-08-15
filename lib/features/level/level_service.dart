class LevelService {
  static Map<String, dynamic> calculateLevel({
    required int totalReports,
    required int verifiedCleanups,
    required double totalCarbon,
  }) {
    final xp = (totalReports * 10) + (verifiedCleanups * 25) + (totalCarbon * 2).toInt();

    int level = 1;
    int xpForNext = 100;
    int xpAccumulated = 0;

    while (xp >= xpAccumulated + xpForNext) {
      xpAccumulated += xpForNext;
      level++;
      xpForNext = 100 * level;
    }

    final progressXp = xp - xpAccumulated;
    final title = _getTitle(level);

    return {
      'level': level,
      'xp': xp,
      'progressXp': progressXp,
      'xpForNext': xpForNext,
      'title': title,
      'progress': progressXp / xpForNext,
    };
  }

  static String _getTitle(int level) {
    if (level >= 50) return 'Earth Guardian';
    if (level >= 30) return 'Climate Champion';
    if (level >= 20) return 'Eco Warrior';
    if (level >= 10) return 'Environmental Scout';
    if (level >= 5) return 'Green Recruit';
    return 'Eco Novice';
  }
}
