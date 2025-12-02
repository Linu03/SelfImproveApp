import 'package:hive/hive.dart';
part 'task.g.dart';

@HiveType(typeId: 0)
enum TaskFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  oneTime,
}

@HiveType(typeId: 1)
enum TaskDifficulty {
  @HiveField(0)
  easy,
  @HiveField(1)
  medium,
  @HiveField(2)
  hard,
}

@HiveType(typeId: 4)
enum TaskCategory {
  @HiveField(0)
  physical,
  @HiveField(1)
  mental,
  @HiveField(2)
  emotional,
  @HiveField(3)
  home,
  @HiveField(4)
  social,
  @HiveField(5)
  financial,
  @HiveField(6)
  productivity,
  @HiveField(7)
  selfCare,
  @HiveField(8)
  learning,
  @HiveField(9)
  career,
  @HiveField(10)
  errands,
  @HiveField(11)
  food,
  @HiveField(12)
  digital,
  @HiveField(13)
  creativity,
  @HiveField(14)
  petCare,
  @HiveField(15)
  maintenance,
  @HiveField(16)
  travel,
  @HiveField(17)
  personalGrowth,
}

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  TaskFrequency frequency;

  @HiveField(4)
  TaskDifficulty difficulty;

  @HiveField(5)
  int coinsReward;

  @HiveField(6)
  int xpReward;

  @HiveField(7)
  TaskCategory category;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.frequency,
    required this.difficulty,
    required this.coinsReward,
    required this.xpReward,
    required this.category,
  });

  static Map<String, int> getRewards(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return {'coins': 5, 'xp': 10};
      case TaskDifficulty.medium:
        return {'coins': 10, 'xp': 25};
      case TaskDifficulty.hard:
        return {'coins': 20, 'xp': 50};
    }
  }

  static String getCategoryLabel(TaskCategory category) {
    const labels = {
      'physical': 'Physical / Health',
      'mental': 'Mental / Intelligence',
      'emotional': 'Emotional / Mindfulness',
      'home': 'Home / Household',
      'social': 'Social / Relationships',
      'financial': 'Financial / Budget',
      'productivity': 'Productivity / Discipline',
      'selfCare': 'Self-care / Personal Care',
      'learning': 'Learning / Education',
      'career': 'Career / Work',
      'errands': 'Errands',
      'food': 'Food / Nutrition',
      'digital': 'Digital Life',
      'creativity': 'Creativity / Hobbies',
      'petCare': 'Pet Care',
      'maintenance': 'Maintenance / Repairs',
      'travel': 'Travel / Logistics',
      'personalGrowth': 'Personal Growth',
    };
    return labels[category.toString().split('.').last] ?? 'Unknown';
  }
}
