import 'package:hive/hive.dart';
import 'journal_models.dart';

// We'll use high typeIds to avoid conflicts
class CompletedTaskSnapshotAdapter extends TypeAdapter<CompletedTaskSnapshot> {
  @override
  final int typeId = 200;

  @override
  CompletedTaskSnapshot read(BinaryReader reader) {
    final taskName = reader.readString();
    final category = reader.readString();
    final xpEarned = reader.readInt();
    final coinsEarned = reader.readInt();
    final completedAt = reader.readString();
    return CompletedTaskSnapshot(
      taskName: taskName,
      category: category,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      completedAt: completedAt,
    );
  }

  @override
  void write(BinaryWriter writer, CompletedTaskSnapshot obj) {
    writer.writeString(obj.taskName);
    writer.writeString(obj.category);
    writer.writeInt(obj.xpEarned);
    writer.writeInt(obj.coinsEarned);
    writer.writeString(obj.completedAt);
  }
}

class UsedRewardSnapshotAdapter extends TypeAdapter<UsedRewardSnapshot> {
  @override
  final int typeId = 201;

  @override
  UsedRewardSnapshot read(BinaryReader reader) {
    final rewardName = reader.readString();
    final durationMinutes = reader.readInt();
    final startedAt = reader.readString();
    final finishedAt = reader.readString();
    return UsedRewardSnapshot(
      rewardName: rewardName,
      durationMinutes: durationMinutes,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );
  }

  @override
  void write(BinaryWriter writer, UsedRewardSnapshot obj) {
    writer.writeString(obj.rewardName);
    writer.writeInt(obj.durationMinutes);
    writer.writeString(obj.startedAt);
    writer.writeString(obj.finishedAt);
  }
}

class JournalDayEntryAdapter extends TypeAdapter<JournalDayEntry> {
  @override
  final int typeId = 202;

  @override
  JournalDayEntry read(BinaryReader reader) {
    final date = reader.readString();
    final completedLen = reader.readInt();
    final completed = <CompletedTaskSnapshot>[];
    for (var i = 0; i < completedLen; i++) {
      completed.add(reader.read() as CompletedTaskSnapshot);
    }
    final usedLen = reader.readInt();
    final used = <UsedRewardSnapshot>[];
    for (var i = 0; i < usedLen; i++) {
      used.add(reader.read() as UsedRewardSnapshot);
    }
    final totalXP = reader.readInt();
    final totalCoins = reader.readInt();
    final totalTasks = reader.readInt();
    final totalRewardMinutes = reader.readInt();
    return JournalDayEntry(
      date: date,
      completedTasks: completed,
      usedRewards: used,
      totalXP: totalXP,
      totalCoins: totalCoins,
      totalTasks: totalTasks,
      totalRewardMinutes: totalRewardMinutes,
    );
  }

  @override
  void write(BinaryWriter writer, JournalDayEntry obj) {
    writer.writeString(obj.date);
    writer.writeInt(obj.completedTasks.length);
    for (final c in obj.completedTasks) writer.write(c);
    writer.writeInt(obj.usedRewards.length);
    for (final u in obj.usedRewards) writer.write(u);
    writer.writeInt(obj.totalXP);
    writer.writeInt(obj.totalCoins);
    writer.writeInt(obj.totalTasks);
    writer.writeInt(obj.totalRewardMinutes);
  }
}
