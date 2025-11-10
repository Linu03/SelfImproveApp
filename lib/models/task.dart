import 'skill_category.dart';


enum TaskFrequency { daily, weekly, monthly, oneTime }

enum TaskDifficulty { easy, medium, hard }

class Task {
  String id;
  String title;
  String description;
  TaskFrequency frequency;
  TaskDifficulty difficulty;
  DateTime? lastCompleted;
  int streak;
  bool completedToday;
  int rewardCoins;
  List<SkillCategory> categoryEffects;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.frequency,
    required this.difficulty,
    this.lastCompleted,
    this.streak = 0,
    this.completedToday = false,
    this.rewardCoins = 0,
    this.categoryEffects = const [],
  });

  void calculateReward() {
    int rewardCoins;
    switch (difficulty) {
      case TaskDifficulty.easy:
        rewardCoins = 10;
        break;
      case TaskDifficulty.medium:
        rewardCoins = 25;
        break;
      case TaskDifficulty.hard:
        rewardCoins = 50;
        break;
    }
    // rewardCoins = baseReward + (streak * 2);
  }
}
