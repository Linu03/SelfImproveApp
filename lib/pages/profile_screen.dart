import 'package:flutter/material.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _currentIndex; // null => no bottom item highlighted on Profile

  void _onNavTap(int index) {
    switch (index) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavbar(
        userSelected: true,
        onShopTap: () => Navigator.pushNamed(context, '/shop'),
      ),
      body: Center(
        child: Text('Profile Screen', style: TextStyle(fontSize: 24)),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
