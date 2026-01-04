import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/top_navbar.dart';
import '../services/journal_service.dart';
import '../models/journal_models.dart';
import 'journal_detail_screen.dart';

class JournalScreen extends StatefulWidget {
  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  int? _currentIndex = 2; // already on Journal

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/add-task');
        break;
      case 2:
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
      body: FutureBuilder(
        future: JournalService.init(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }

          final box = Hive.box<JournalDayEntry>('journalBox');
          return ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box<JournalDayEntry> b, _) {
              final entries = b.values.toList();
              entries.sort((a, b) => b.date.compareTo(a.date));
              if (entries.isEmpty) {
                return Center(child: Text('No journal entries yet'));
              }
              return ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => Divider(height: 1),
                itemBuilder: (context, idx) {
                  final e = entries[idx];
                  return ListTile(
                    title: Text(e.date),
                    subtitle: Text(
                      '${e.totalTasks} tasks • ${e.totalXP} XP • ${e.totalCoins} coins',
                    ),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JournalDetailScreen(entry: e),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
