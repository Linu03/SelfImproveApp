import 'package:hive/hive.dart';
import '../models/category_xp.dart';
import '../models/task.dart';

class CategoryXpRepository {
  static const String boxName = 'categoryXpBox';

  Future<Box<CategoryXp>> openBox() async {
    return await Hive.openBox<CategoryXp>(boxName);
  }

  Future<CategoryXp> getStats(TaskCategory category) async {
    final box = await openBox();
    final key = category.toString().split('.').last;
    if (box.containsKey(key)) {
      return box.get(key)!;
    }
    final stats = CategoryXp(categoryName: key);
    await box.put(key, stats);
    return stats;
  }

  Future<void> saveStats(TaskCategory category, CategoryXp stats) async {
    final box = await openBox();
    final key = category.toString().split('.').last;
    await box.put(key, stats);
  }

  /// Add XP to a specific category and handle leveling
  Future<CategoryXp> addXpToCategory(TaskCategory category, int xpToAdd) async {
    final stats = await getStats(category);
    stats.totalXp += xpToAdd;

    // Simple leveling rule: xp needed = 100 * level
    while (stats.totalXp >= _xpForNextLevel(stats.level)) {
      stats.totalXp -= _xpForNextLevel(stats.level);
      stats.level += 1;
    }

    await saveStats(category, stats);
    return stats;
  }

  /// Get all category stats
  Future<Map<TaskCategory, CategoryXp>> getAllCategoryStats() async {
    final box = await openBox();
    final result = <TaskCategory, CategoryXp>{};

    for (final category in TaskCategory.values) {
      final key = category.toString().split('.').last;
      final stats = box.get(key) ?? CategoryXp(categoryName: key);
      result[category] = stats;
    }

    return result;
  }

  int _xpForNextLevel(int level) => 100 * level;

  int xpForNextLevelOf(CategoryXp stats) => _xpForNextLevel(stats.level);
}
