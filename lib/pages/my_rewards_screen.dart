import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'dart:typed_data';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../services/exact_alarm_service.dart';

import '../models/reward_item.dart';
import '../services/reward_background.dart';
import '../services/journal_service.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';

/// MyRewardsScreen
/// - Shows purchased rewards (from 'activeRewardsBox')
/// - Allows activation of a reward (starts a countdown)
/// - Persists startTime and remainingMinutes into Hive
/// - Schedules local notification when the reward expires
class MyRewardsScreen extends StatefulWidget {
  @override
  _MyRewardsScreenState createState() => _MyRewardsScreenState();
}

class _MyRewardsScreenState extends State<MyRewardsScreen>
    with WidgetsBindingObserver {
  late Box<RewardItem> _activeBox;
  bool _boxReady = false;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Map<dynamic, int> _scheduledIds = {}; // key -> notification id
  int _nextNotifId = 1000;

  Timer? _ticker;
  bool?
  _canScheduleExactAlarms; // null = unknown, true = allowed, false = denied

  final Set<dynamic> _expiringKeys = {};
  bool _checkingExpirations = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registerAdapterIfNeeded();
    _openBox();
    _initNotifications();
    // Keep a UI-only ticker to refresh remaining time while app is open
    _startUITicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  void _registerAdapterIfNeeded() {
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(RewardItemAdapter());
    }
  }

  Future<void> _openBox() async {
    _activeBox = await Hive.openBox<RewardItem>('activeRewardsBox');
    // On startup, reconcile active reward timers
    _reconcileActiveRewards();
    setState(() {
      _boxReady = true;
    });
  }

  Future<void> _initNotifications() async {
    // Initialize timezone database for zoned scheduling and set local zone to Romania
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Bucharest'));
      print('[MyRewards] Timezone set to Europe/Bucharest');
    } catch (e) {
      print('[MyRewards] Failed to set timezone: $e');
    }

    // Initialize notification channel for high importance + vibration + sound
    const channel = AndroidNotificationChannel(
      'rewards_channel',
      'Rewards',
      description: 'Notifications for reward expirations',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(android: androidInit);
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // If user taps the notification, ensure we reconcile expirations
        await _reconcileActiveRewards();
      },
    );

    // Create channel on Android
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(channel);

    // On Android check whether exact alarms are allowed and update UI state
    if (Platform.isAndroid) {
      await _updateExactAlarmPermissionStatus();
    }
  }

  // UI-only ticker: updates countdown display while app is open. Does not expire rewards.
  void _startUITicker() {
    _ticker = Timer.periodic(Duration(seconds: 1), (_) async {
      if (!mounted) return;
      // UI refresh
      setState(() {});
      // Periodically check expirations while the app is in foreground
      if (!_checkingExpirations) {
        _checkingExpirations = true;
        try {
          await _checkExpirations();
        } catch (e) {
          print('[MyRewards] _startUITicker: _checkExpirations error: $e');
        } finally {
          _checkingExpirations = false;
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateExactAlarmPermissionStatus();
    }
    super.didChangeAppLifecycleState(state);
  }

  /// Show an explanatory dialog and open the exact-alarm settings when requested.
  Future<void> _ensureExactAlarmsPermission() async {
    try {
      final shouldPrompt =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Allow exact alarms'),
              content: Text(
                'To ensure rewards expire precisely even when the app is closed, please allow exact alarms for this app in system settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Not now'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Open settings'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldPrompt) {
        await _openExactAlarmSettings();
      }
    } catch (e) {
      // ignore issues opening settings
    }
  }

  Future<void> _openExactAlarmSettings() async {
    try {
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      );
      await intent.launch();
    } catch (e) {
      // ignore
    }
  }

  Future<void> _updateExactAlarmPermissionStatus() async {
    try {
      final allowed = await ExactAlarmService.canScheduleExactAlarms();
      setState(() {
        _canScheduleExactAlarms = allowed;
      });
    } catch (e) {
      setState(() {
        _canScheduleExactAlarms = false;
      });
    }
  }

  /// Opens the system page where the user can disable battery optimizations.
  Future<void> _openBatteryOptimizationSettings() async {
    try {
      final intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      );
      await intent.launch();
    } catch (e) {
      // ignore
    }
  }

  /// Opens the app's notification settings (Android 8+). This helps on Android 13+ when
  /// POST_NOTIFICATIONS may be required and the user needs to enable notifications.
  Future<void> _openAppNotificationSettings() async {
    try {
      final intent = AndroidIntent(
        action: 'android.settings.APP_NOTIFICATION_SETTINGS',
      );
      await intent.launch();
    } catch (e) {
      // ignore
    }
  }

  /// Optional: request notification permission via permission_handler plugin (recommended)
  /// Add `permission_handler` to pubspec.yaml and call this function to request POST_NOTIFICATIONS at runtime on Android 13+.
  Future<void> _requestNotificationPermission() async {
    try {
      // If permission_handler is added, uncomment below:
      // final status = await Permission.notification.request();
      // if (status.isGranted) { /* good */ }
      // Otherwise open app notification settings as a fallback
      await _openAppNotificationSettings();
    } catch (e) {
      // ignore
    }
  }

  Future<void> _reconcileActiveRewards() async {
    // Called at startup to update remaining times and expire rewards if needed
    print('[MyRewards] Reconciling active rewards...');
    final now = DateTime.now();

    for (final key in _activeBox.keys) {
      final reward = _activeBox.get(key);
      if (reward == null) continue;

      if (reward.isActive && reward.startTime != null) {
        final elapsedSeconds = now.difference(reward.startTime!).inSeconds;
        final initialSeconds = (reward.remainingMinutes * 60);
        final remainingSeconds = initialSeconds - elapsedSeconds;
        if (remainingSeconds <= 0) {
          // Expired while app was closed
          await _expireReward(key);
        } else {
          // Still active: (re) schedule notification for end time
          final id = _getOrCreateNotifIdForKey(key);
          await _scheduleNotificationById(id, key, reward, remainingSeconds);
        }
      }
    }
  }

  int _notifIdForKey(dynamic key) {
    if (key is int) return key;
    return (key.hashCode & 0x7FFFFFFF);
  }

  int _getOrCreateNotifIdForKey(dynamic key) {
    if (_scheduledIds.containsKey(key)) return _scheduledIds[key]!;
    final id = _notifIdForKey(key);
    _scheduledIds[key] = id;
    return id;
  }

  Future<void> _scheduleNotification(dynamic key, RewardItem reward) async {
    if (reward.startTime == null) return;
    final elapsedSeconds = DateTime.now()
        .difference(reward.startTime!)
        .inSeconds;
    final initialSeconds = reward.remainingMinutes * 60;
    final remainingSeconds = initialSeconds - elapsedSeconds;
    if (remainingSeconds <= 0) return;

    final id = _getOrCreateNotifIdForKey(key);
    await _scheduleNotificationById(id, key, reward, remainingSeconds);
  }

  Future<void> _scheduleNotificationById(
    int id,
    dynamic key,
    RewardItem reward,
    int remainingSeconds,
  ) async {
    final endTime = DateTime.now().add(Duration(seconds: remainingSeconds));
    print(
      '[MyRewards] Scheduling notification for key=$key id=$id end=$endTime',
    );
    try {
      // Cancel any previous scheduled notification/alarm for this id to avoid duplicates
      try {
        await _notifications.cancel(id);
      } catch (e) {
        // ignore
      }
      try {
        if (Platform.isAndroid) await AndroidAlarmManager.cancel(id);
      } catch (e) {
        // ignore
      }

      // Schedule using zonedSchedule with timezone-aware DateTime
      await _notifications.zonedSchedule(
        id,
        'Reward expired',
        'Timpul pentru ${reward.name} s-a terminat!',
        tz.TZDateTime.from(endTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'rewards_channel',
            'Rewards',
            channelDescription: 'Notifications for reward expirations',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      // On Android schedule an exact alarm that will run a background isolate
      // to mark rewards expired even if the app is terminated.
      if (Platform.isAndroid) {
        await AndroidAlarmManager.oneShotAt(
          endTime,
          id,
          expireDueRewardsCallback,
          exact: true,
          wakeup: true,
        );
        print('[MyRewards] Android alarm scheduled for id=$id');
      }
    } catch (e) {
      print(
          '[MyRewards] _scheduleNotificationById error for key=$key id=$id: $e',
      );
    }
  }

  Future<void> _cancelScheduledNotificationForKey(dynamic key) async {
    final id = _scheduledIds.containsKey(key)
        ? _scheduledIds[key]
        : _notifIdForKey(key);
    if (id != null) {
      print(
          '[MyRewards] Cancelling scheduled notification/alarm for key=$key id=$id',
      );
      try {
        await _notifications.cancel(id!);
      } catch (e) {}
      _scheduledIds.remove(key);
      // Also cancel Android alarm if scheduled
      try {
        if (Platform.isAndroid) await AndroidAlarmManager.cancel(id);
      } catch (e) {
        // ignore
      }
    }
  }

  Future<void> _showNotificationNowWithId(
    int id,
    String title,
    String body,
  ) async {
    print('[MyRewards] Showing notification id=$id title="$title"');
    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'rewards_channel',
          'Rewards',
          channelDescription: 'Notifications for reward expirations',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> _expireReward(dynamic key) async {
    if (_expiringKeys.contains(key)) {
      print('[MyRewards] _expireReward: already expiring $key');
      return;
    }
    _expiringKeys.add(key);
    try {
      final reward = _activeBox.get(key);
      if (reward == null) return;

      // If already not active and no remaining minutes, skip
      if (!reward.isActive && reward.remainingMinutes == 0) {
        print('[MyRewards] _expireReward: reward $key already expired');
        return;
      }

      print('[MyRewards] _expireReward: expiring reward $key (${reward.name})');

      // Capture metadata for journal before modifying the reward
      final startedAt = reward.startTime;
      final durationMinutes = reward.remainingMinutes;

      // Mark expired in Hive
      reward.isActive = false;
      reward.startTime = null;
      reward.remainingMinutes = 0;
      await reward.save();

      // Record used reward in journal
      try {
        if (startedAt != null) {
          await JournalService.addUsedReward(
            startedAt: startedAt,
            finishedAt: DateTime.now(),
            rewardName: reward.name,
            durationMinutes: durationMinutes,
          );
        }
      } catch (e) {
        // ignore journal errors
      }

      // Cancel scheduled notification/alarm
      final id = _notifIdForKey(key);
      try {
        await _notifications.cancel(id);
      } catch (e) {}
      try {
        if (Platform.isAndroid) await AndroidAlarmManager.cancel(id);
      } catch (e) {}

      // Send a single notification
      await _showNotificationNowWithId(
        id,
        'Reward expired',
        'Timpul pentru ${reward.name} s-a terminat!',
      );
    } finally {
      _expiringKeys.remove(key);
    }
  }

  Future<void> _checkExpirations() async {
    final now = DateTime.now();
    for (final key in _activeBox.keys) {
      final r = _activeBox.get(key);
      if (r == null) continue;

      if (r.isActive && r.startTime != null) {
        final elapsed = now.difference(r.startTime!).inSeconds;
        final initialSeconds = r.remainingMinutes * 60;
        final remaining = initialSeconds - elapsed;
        if (remaining <= 0) {
          print(
            '[MyRewards] _checkExpirations: reward $key expired while foregrounded',
          );
          await _expireReward(key);
        }
      }
    }
  }

  int _getCurrentRemainingSeconds(RewardItem r) {
    if (r.isActive && r.startTime != null) {
      final elapsed = DateTime.now().difference(r.startTime!).inSeconds;
      final initialSeconds = r.remainingMinutes * 60;
      final remaining = initialSeconds - elapsed;
      return remaining > 0 ? remaining : 0;
    }
    return r.remainingMinutes * 60;
  }

  String _formatSeconds(int seconds) {
    if (seconds <= 0) return '0:00';
    final d = Duration(seconds: seconds);
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _activateReward(dynamic key, RewardItem reward) async {
    if (reward.remainingMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No time left for ${reward.name}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    reward.isActive = true;
    reward.startTime = DateTime.now();
    // remainingMinutes here is treated as "initial remaining at start"
    await reward.save();
    await _scheduleNotification(key, reward);

    // Scheduling done; _scheduleNotificationById already arranges the alarm.
    print(
      '[MyRewards] Activated reward for key=$key name=${reward.name} duration=${reward.remainingMinutes}min',
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1625), // Dark fantasy background
      appBar: TopNavbar(
        onUserTap: () => Navigator.pushNamed(context, '/profile'),
        onShopTap: () => Navigator.pushNamed(context, '/shop'),
        title: 'My Rewards',
        userSelected: false,
        shopSelected: false,
      ),
      body: _boxReady
          ? ValueListenableBuilder<Box<RewardItem>>(
              valueListenable: _activeBox.listenable(),
              builder: (context, box, _) {
                final keys = box.keys.where((k) {
                  final reward = box.get(k);
                  if (reward == null) return false;
                  final expired =
                      (!reward.isActive) && (reward.remainingMinutes == 0);
                  return !expired;
                }).toList();
                if (keys.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.purple.shade700.withOpacity(0.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Empty Inventory',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No rewards yet. Buy them from the Shop!',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    // Inventory Header
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2d1b3d),
                            const Color(0xFF1a1625),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.purple.shade700.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            color: Colors.purple.shade300,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Buffs & Consumables',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade200,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${keys.length} item${keys.length != 1 ? 's' : ''} in inventory',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.purple.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => _reconcileActiveRewards(),
                        color: Colors.purple.shade400,
                        backgroundColor: const Color(0xFF2d1b3d),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: keys.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final key = keys[index];
                            final reward = box.get(key)!;
                            final currentRemaining =
                                _getCurrentRemainingSeconds(reward);
                            final totalSeconds =
                                (reward.durationMinutes ??
                                    reward.remainingMinutes) *
                                60;
                            final progress = totalSeconds > 0
                                ? (1 - (currentRemaining / totalSeconds)).clamp(
                                    0.0,
                                    1.0,
                                  )
                                : 0.0;

                            final expired =
                                (!reward.isActive) &&
                                (reward.remainingMinutes == 0);

                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2d1b3d),
                                    const Color(0xFF1f1529),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: reward.isActive
                                      ? Colors.green.shade600.withOpacity(0.5)
                                      : Colors.purple.shade800.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: reward.isActive
                                    ? [
                                        BoxShadow(
                                          color: Colors.green.shade900
                                              .withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Status Icon
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: reward.isActive
                                                ? Colors.green.shade900
                                                    .withOpacity(0.3)
                                                : Colors.grey.shade900
                                                    .withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: reward.isActive
                                                  ? Colors.green.shade600
                                                      .withOpacity(0.4)
                                                  : Colors.grey.shade700
                                                      .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Icon(
                                            reward.isActive
                                                ? Icons.flash_on
                                                : Icons.hourglass_empty,
                                            color: reward.isActive
                                                ? Colors.green.shade300
                                                : Colors.grey.shade500,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                reward.name,
                                                style: TextStyle(
                                                  color: reward.isActive
                                                      ? Colors.amber.shade200
                                                      : Colors.grey.shade300,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 14,
                                                    color: Colors.cyan.shade400,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Total: ${reward.durationMinutes ?? reward.remainingMinutes} min',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.cyan.shade400,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Status Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: reward.isActive
                                                  ? [
                                                      Colors.green.shade600,
                                                      Colors.green.shade800,
                                                    ]
                                                  : [
                                                      Colors.grey.shade700,
                                                      Colors.grey.shade800,
                                                    ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: reward.isActive
                                                ? [
                                                    BoxShadow(
                                                      color: Colors
                                                          .green.shade900
                                                          .withOpacity(0.5),
                                                      blurRadius: 6,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Text(
                                            reward.isActive
                                                ? 'ACTIVE'
                                                : 'READY',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (reward.isActive)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Progress Bar
                                          Container(
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.green.shade900
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                backgroundColor:
                                                    Colors.transparent,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Colors.green.shade400,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.timer,
                                                    size: 16,
                                                    color:
                                                        Colors.green.shade300,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Remaining: ${_formatSeconds(currentRemaining)}',
                                                    style: TextStyle(
                                                      color: Colors
                                                          .green.shade200,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '${(progress * 100).toInt()}%',
                                                style: TextStyle(
                                                  color: Colors.green.shade400,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                size: 16,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Available: ${_formatSeconds(currentRemaining)}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            height: 38,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: (expired ||
                                                        reward.remainingMinutes <=
                                                            0)
                                                    ? [
                                                        Colors.grey.shade700,
                                                        Colors.grey.shade800,
                                                      ]
                                                    : [
                                                        Colors.amber.shade600,
                                                        Colors.amber.shade800,
                                                      ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: (expired ||
                                                      reward.remainingMinutes <=
                                                          0)
                                                  ? null
                                                  : [
                                                      BoxShadow(
                                                        color: Colors
                                                            .amber.shade900
                                                            .withOpacity(0.5),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: (expired ||
                                                        reward.remainingMinutes <=
                                                            0)
                                                    ? null
                                                    : () => _activateReward(
                                                        key, reward),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                splashColor: Colors.white
                                                    .withOpacity(0.2),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 20,
                                                  ),
                                                  child: Center(
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.play_arrow,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          'START',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                            letterSpacing: 0.8,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          : Center(
              child: CircularProgressIndicator(
                color: Colors.purple.shade400,
                strokeWidth: 3,
              ),
            ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/add-task');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/journal');
              break;
          }
        },
      ),
    );
  }
}
