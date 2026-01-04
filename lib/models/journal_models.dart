// Manual journal models (we use manual TypeAdapters in journal_adapters.dart).

class CompletedTaskSnapshot {
  final String taskName;
  final String category;
  final int xpEarned;
  final int coinsEarned;
  final String completedAt; // hh:mm
  final bool completed; // true = completed (+XP), false = failed (-XP)

  CompletedTaskSnapshot({
    required this.taskName,
    required this.category,
    required this.xpEarned,
    required this.coinsEarned,
    required this.completedAt,
    this.completed = true,
  });
}

class UsedRewardSnapshot {
  final String rewardName;
  final int durationMinutes;
  final String startedAt; // hh:mm
  final String finishedAt; // hh:mm

  UsedRewardSnapshot({
    required this.rewardName,
    required this.durationMinutes,
    required this.startedAt,
    required this.finishedAt,
  });
}

class JournalDayEntry {
  final String date; // yyyy-MM-dd
  final List<CompletedTaskSnapshot> completedTasks;
  final List<UsedRewardSnapshot> usedRewards;
  int totalXP;
  int totalCoins;
  int totalTasks;
  int totalRewardMinutes;

  JournalDayEntry({
    required this.date,
    List<CompletedTaskSnapshot>? completedTasks,
    List<UsedRewardSnapshot>? usedRewards,
    this.totalXP = 0,
    this.totalCoins = 0,
    this.totalTasks = 0,
    this.totalRewardMinutes = 0,
  }) : completedTasks = completedTasks ?? [],
       usedRewards = usedRewards ?? [];
}
