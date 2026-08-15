import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const _lastActiveKey = 'last_active_date';
  static const _streakKey = 'current_streak';
  static const _longestKey = 'longest_streak';

  static Future<Map<String, int>> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    final lastActive = prefs.getString(_lastActiveKey);
    int currentStreak = prefs.getInt(_streakKey) ?? 0;
    int longestStreak = prefs.getInt(_longestKey) ?? 0;

    if (lastActive == null) {
      currentStreak = 1;
    } else {
      final lastParts = lastActive.split('-').map(int.parse).toList();
      final lastDate = DateTime(lastParts[0], lastParts[1], lastParts[2]);
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      final diff = todayDateOnly.difference(lastDate).inDays;

      if (diff == 0) {
        // same day, no change
      } else if (diff == 1) {
        currentStreak += 1;
      } else {
        currentStreak = 1;
      }
    }

    if (currentStreak > longestStreak) longestStreak = currentStreak;

    await prefs.setString(_lastActiveKey, todayStr);
    await prefs.setInt(_streakKey, currentStreak);
    await prefs.setInt(_longestKey, longestStreak);

    print('Streak: current=$currentStreak longest=$longestStreak');
    return {'current': currentStreak, 'longest': longestStreak};
  }

  static Future<Map<String, int>> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'current': prefs.getInt(_streakKey) ?? 0,
      'longest': prefs.getInt(_longestKey) ?? 0,
    };
  }
}
