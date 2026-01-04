import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/reward_item.dart';
import 'journal_service.dart';

// This callback runs in a background isolate (Android Alarm Manager).
// It will scan activeRewardsBox and mark any rewards whose end time has
// passed as expired. Annotated as entry point so it is accessible by
// the background isolate.
@pragma('vm:entry-point')
Future<void> expireDueRewardsCallback() async {
  try {
    // Obtain app documents directory for Hive initialization
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    // Register adapter if not already
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(RewardItemAdapter());

    final box = await Hive.openBox<RewardItem>('activeRewardsBox');
    final now = DateTime.now();

    // Ensure journal adapters/box are ready in this isolate
    try {
      await JournalService.init();
    } catch (e) {
      // ignore
    }

    // Prepare notifications for background (Android isolate)
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();
    final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notifications.initialize(
      InitializationSettings(android: androidInit),
    );

    // Ensure channel exists in background isolate
    final androidPlugin = notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final channel = AndroidNotificationChannel(
      'rewards_channel',
      'Rewards',
      description: 'Notifications for reward expirations',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin?.createNotificationChannel(channel);

    final expiredKeys = <dynamic>[];
    for (final key in box.keys) {
      final r = box.get(key);
      if (r == null) continue;
      if (r.isActive && r.startTime != null) {
        final elapsed = now.difference(r.startTime!).inSeconds;
        final initialSeconds = r.remainingMinutes * 60;
        if (elapsed >= initialSeconds) {
          final startedAt = r.startTime;
          final durationMinutes = r.remainingMinutes;

          r.isActive = false;
          r.startTime = null;
          r.remainingMinutes = 0;
          await r.save();
          expiredKeys.add(key);

          // Record in journal
          try {
            if (startedAt != null) {
              await JournalService.addUsedReward(
                startedAt: startedAt,
                finishedAt: DateTime.now(),
                rewardName: r.name,
                durationMinutes: durationMinutes,
              );
            }
          } catch (e) {
            // ignore
          }

          // Show notification for this expired reward
          final androidDetails = AndroidNotificationDetails(
            'rewards_channel',
            'Rewards',
            channelDescription: 'Notifications for reward expirations',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );

          final id = key is int ? key : (key.hashCode & 0x7FFFFFFF);
          try {
            print('[RewardBackground] Cancelling scheduled notif for id=$id');
            await notifications.cancel(id);
          } catch (e) {}

          print(
            '[RewardBackground] Posting expiry notification for key=$key id=$id name=${r.name}',
          );
          await notifications.show(
            id,
            'Reward expired',
            'Timpul pentru ${r.name} s-a terminat!',
            NotificationDetails(android: androidDetails),
          );
        }
      }
    }

    // Log to persistent storage so we can see whether background callback ran
    try {
      final logBox = await Hive.openBox('bgLogs');
      await logBox.add({
        'time': DateTime.now().toIso8601String(),
        'expired': expiredKeys.map((k) => k.toString()).toList(),
      });
      await logBox.close();
      print(
        '[RewardBackground] expireDueRewardsCallback logged ${expiredKeys.length} expirations',
      );
    } catch (e) {
      print('[RewardBackground] Failed to write bg log: $e');
    }

    await box.close();
  } catch (e) {
    // Background code must not throw uncaught exceptions
  }
}
