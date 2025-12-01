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

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.frequency,
    required this.difficulty,
    required this.coinsReward,
    required this.xpReward,
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
}
