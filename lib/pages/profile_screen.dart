import 'package:flutter/material.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/xp_bar.dart';
import '../widgets/hp_bar.dart';
import '../services/user_stats_repository.dart';
import '../models/user_stats.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _currentIndex; // null => no bottom item highlighted on Profile
  final UserStatsRepository _statsRepo = UserStatsRepository();
  UserStats? _stats;

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
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await _statsRepo.getStats();
    setState(() => _stats = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavbar(
        userSelected: true,
        onShopTap: () => Navigator.pushNamed(context, '/shop'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_stats != null)
              XpBar(
                currentXp: _stats!.totalXp,
                xpForNextLevel: _statsRepo.xpForNextLevelOf(_stats!),
                level: _stats!.level,
              )
            else
              const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 24),
            if (_stats != null)
              HpBar(currentHp: _stats!.totalHp, maxHp: _statsRepo.getMaxHp())
            else
              const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 24),
            Text('Total XP: ${_stats?.totalXp ?? 0}'),
            Text('Level: ${_stats?.level ?? 1}'),
            Text('HP: ${_stats?.totalHp ?? 100}'),
            const SizedBox(height: 12),
            const Text('Other profile details go here...'),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
