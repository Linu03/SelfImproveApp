import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
import './pages/splash_screen.dart';
import './pages/home_screen.dart';
import './pages/journal_screen.dart';
import './pages/add_task_screen.dart';
import './pages/profile_screen.dart';
import './pages/shop_screen.dart';
import './pages/my_rewards_screen.dart';
import './models/task.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import './models/user_stats.dart';
import './services/journal_service.dart';
import './models/category_xp.dart';
import './models/user_profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskFrequencyAdapter());
  Hive.registerAdapter(TaskDifficultyAdapter());
  Hive.registerAdapter(TaskCategoryAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(UserStatsAdapter());
  Hive.registerAdapter(CategoryXpAdapter());
  Hive.registerAdapter(UserProfileAdapter());

  await Hive.openBox<Task>('tasksBox');
  await Hive.openBox<UserStats>('userBox');
  await Hive.openBox<CategoryXp>('categoryXpBox');
  await Hive.openBox<UserProfile>('userProfileBox');

  // Initialize journal storage
  try {
    await JournalService.init();
  } catch (e) {
    // ignore journal init errors
  }

  // Initialize Android alarm manager for background reward expirations
  try {
    // Initialize Android alarm manager for background reward expirations
    await AndroidAlarmManager.initialize();
  } catch (e) {
    // ignore initialization errors on platforms where not supported
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Multi-Page App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => HomeScreen(),
        '/add-task': (context) => AddTaskScreen(),
        '/journal': (context) => JournalScreen(),
        '/profile': (context) => ProfileScreen(),
        '/shop': (context) => ShopScreen(),
        '/my-rewards': (context) => MyRewardsScreen(),
      },
    );
  }
}
