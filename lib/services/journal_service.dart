import 'package:hive/hive.dart';
import '../models/journal_models.dart';
import '../models/journal_adapters.dart';

class JournalService {
  static const String boxName = 'journalBox';
  static Box<JournalDayEntry>? _box;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(200))
      Hive.registerAdapter(CompletedTaskSnapshotAdapter());
    if (!Hive.isAdapterRegistered(201))
      Hive.registerAdapter(UsedRewardSnapshotAdapter());
    if (!Hive.isAdapterRegistered(202))
      Hive.registerAdapter(JournalDayEntryAdapter());
    _box = await Hive.openBox<JournalDayEntry>(boxName);
  }

  static String _dateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static Future<JournalDayEntry> getOrCreateForDate(DateTime d) async {
    _box ??= await Hive.openBox<JournalDayEntry>(boxName);
    final key = _dateKey(d);
    if (_box!.containsKey(key)) return _box!.get(key)!;
    final entry = JournalDayEntry(date: key);
    await _box!.put(key, entry);
    return entry;
  }

  static Future<void> addCompletedTask({
    required DateTime when,
    required String taskName,
    required String category,
    required int xpEarned,
    required int coinsEarned,
  }) async {
    final entry = await getOrCreateForDate(when);
    final completedAt =
        '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    final snap = CompletedTaskSnapshot(
      taskName: taskName,
      category: category,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      completedAt: completedAt,
    );
    entry.completedTasks.add(snap);
    entry.totalXP += xpEarned;
    entry.totalCoins += coinsEarned;
    entry.totalTasks = entry.completedTasks.length;
    await _box!.put(entry.date, entry);
  }

  static Future<void> addUsedReward({
    required DateTime startedAt,
    required DateTime finishedAt,
    required String rewardName,
    required int durationMinutes,
  }) async {
    final entry = await getOrCreateForDate(startedAt);
    final start =
        '${startedAt.hour.toString().padLeft(2, '0')}:${startedAt.minute.toString().padLeft(2, '0')}';
    final finish =
        '${finishedAt.hour.toString().padLeft(2, '0')}:${finishedAt.minute.toString().padLeft(2, '0')}';
    final snap = UsedRewardSnapshot(
      rewardName: rewardName,
      durationMinutes: durationMinutes,
      startedAt: start,
      finishedAt: finish,
    );
    entry.usedRewards.add(snap);
    entry.totalRewardMinutes += durationMinutes;
    await _box!.put(entry.date, entry);
  }

  static List<JournalDayEntry> allEntries() {
    if (_box == null) return [];
    final entries = _box!.values.toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
