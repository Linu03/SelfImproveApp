import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/top_navbar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int? _currentIndex = 0;

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/add-task');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/journal');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavbar(
        onUserTap: () => Navigator.pushNamed(context, '/profile'),
        onShopTap: () => Navigator.pushNamed(context, '/shop'),
      ),
      body: Center(
        child: Text('This is the Home Screen', style: TextStyle(fontSize: 24)),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
