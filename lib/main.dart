import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
import './pages/splash_screen.dart';
import './pages/home_screen.dart';
import './pages/journal_screen.dart';
import './pages/add_task_screen.dart';
import './pages/profile_screen.dart';
import './pages/shop_screen.dart';
import './models/task.dart';
import './models/user_stats.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskFrequencyAdapter());
  Hive.registerAdapter(TaskDifficultyAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(UserStatsAdapter());
  await Hive.openBox<Task>('tasksBox');
  await Hive.openBox<UserStats>('userBox');
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
      },
    );
  }
}
