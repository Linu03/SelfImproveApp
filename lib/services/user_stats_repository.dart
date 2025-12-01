import 'package:hive/hive.dart';
import '../models/user_stats.dart';

class UserStatsRepository {
  static const String boxName = 'userBox';
  static const String statsKey = 'userStats';

  Future<Box<UserStats>> openBox() async {
    return await Hive.openBox<UserStats>(boxName);
  }

  Future<UserStats> getStats() async {
    final box = await openBox();
    if (box.containsKey(statsKey)) {
      return box.get(statsKey)!;
    }
    final stats = UserStats();
    await box.put(statsKey, stats);
    return stats;
  }

  Future<void> saveStats(UserStats stats) async {
    final box = await openBox();
    await box.put(statsKey, stats);
  }

  /// Add XP and handle leveling. Returns the updated UserStats.
  Future<UserStats> addXp(int xpToAdd) async {
    final stats = await getStats();
    stats.totalXp += xpToAdd;

    // Simple leveling rule: xp needed = 100 * level
    while (stats.totalXp >= _xpForNextLevel(stats.level)) {
      stats.totalXp -= _xpForNextLevel(stats.level);
      stats.level += 1;
    }

    await saveStats(stats);
    return stats;
  }

  int _xpForNextLevel(int level) => 100 * level;

  int xpForNextLevelOf(UserStats stats) => _xpForNextLevel(stats.level);
}
