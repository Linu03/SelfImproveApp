import 'package:flutter/material.dart';
import './pages/splash_screen.dart';
import './pages/home_screen.dart';
import './pages/journal_screen.dart';
import './pages/add_task_screen.dart';
import './pages/profile_screen.dart';
import './pages/shop_screen.dart';

void main() {
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
