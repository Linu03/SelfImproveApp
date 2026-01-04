import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';

import '../models/reward_item.dart';
import 'journal_service.dart';

@pragma('vm:entry-point')
// This callback runs in the background isolate on Android when the alarm fires.
// It must be a top-level function.
Future<void> rewardAlarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive in this isolate
  await Hive.initFlutter();

  // Register adapter if necessary
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(RewardItemAdapter());
  }

  final box = await Hive.openBox<RewardItem>('activeRewardsBox');
  final reward = box.get(id);
  if (reward != null && reward.isActive) {
    final startedAt = reward.startTime;
    final durationMinutes = reward.remainingMinutes;

    // Mark expired
    reward.isActive = false;
    reward.startTime = null;
    reward.remainingMinutes = 0;
    await reward.save();

    // Record in journal
    try {
      if (startedAt != null) {
        await JournalService.init();
        await JournalService.addUsedReward(
          startedAt: startedAt,
          finishedAt: DateTime.now(),
          rewardName: reward.name,
          durationMinutes: durationMinutes,
        );
      }
    } catch (e) {
      // ignore
    }
  }

  // Initialize notifications in this isolate and show notification
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(InitializationSettings(android: androidInit));

  final androidDetails = AndroidNotificationDetails(
    'rewards_channel',
    'Rewards',
    channelDescription: 'Notifications for reward expirations',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  // Log invocation into bgLogs so we can tell if this callback ran while app was killed
  try {
    final logBox = await Hive.openBox('bgLogs');
    await logBox.add({
      'time': DateTime.now().toIso8601String(),
      'alarmId': id,
      'note': 'rewardAlarmCallback invoked',
    });
    await logBox.close();
    print('[RewardAlarm] Logged alarm invocation id=$id');
  } catch (e) {
    print('[RewardAlarm] Failed to write bg log: $e');
  }

  await notifications.show(
    id, // use id so it's unique per reward
    'Reward expired',
    reward != null
        ? 'Timpul pentru ${reward.name} s-a terminat!'
        : 'A reward expired',
    NotificationDetails(android: androidDetails),
  );

  await box.close();
}
