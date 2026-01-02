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

      // Mark expired in Hive
      reward.isActive = false;
      reward.startTime = null;
      reward.remainingMinutes = 0;
      await reward.save();

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
        SnackBar(content: Text('No time left for ${reward.name}')),
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
                final rewards = box.values.toList();
                if (rewards.isEmpty) {
                  return Center(
                    child: Text('No rewards yet. Buy them from the Shop!'),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => _reconcileActiveRewards(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: rewards.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final reward = rewards[index];
                            final key = box.keyAt(index);
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

                            return Opacity(
                              opacity: expired ? 0.45 : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.indigo.shade600,
                                      Colors.blue.shade700,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  reward.name,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Total: ${reward.durationMinutes ?? reward.remainingMinutes} min',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (expired)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade900
                                                    .withOpacity(0.6),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Expired',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (reward.isActive)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 10,
                                              backgroundColor: Colors.white24,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.amber.shade400,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Remaining: ${_formatSeconds(currentRemaining)}',
                                              style: TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Remaining: ${_formatSeconds(currentRemaining)}',
                                              style: TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed:
                                                  (expired ||
                                                      reward.remainingMinutes <=
                                                          0)
                                                  ? null
                                                  : () => _activateReward(
                                                      key,
                                                      reward,
                                                    ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.amber.shade400,
                                                foregroundColor: Colors.black87,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text('Start'),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
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
          : Center(child: CircularProgressIndicator()),
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
