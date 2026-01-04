import 'package:flutter/material.dart';
import '../models/journal_models.dart';

class JournalDetailScreen extends StatelessWidget {
  final JournalDayEntry entry;

  const JournalDetailScreen({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Journal — ${entry.date}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Totals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  Chip(label: Text('XP: ${entry.totalXP}')),
                  Chip(label: Text('Coins: ${entry.totalCoins}')),
                  Chip(label: Text('Tasks: ${entry.totalTasks}')),
                  Chip(
                    label: Text('Reward minutes: ${entry.totalRewardMinutes}'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (entry.completedTasks.isNotEmpty) ...[
                Text(
                  'Completed Tasks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...entry.completedTasks.map(
                  (c) => ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(c.taskName),
                    subtitle: Text('${c.category} • ${c.completedAt}'),
                    trailing: Text('+${c.xpEarned}xp • +${c.coinsEarned}'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (entry.usedRewards.isNotEmpty) ...[
                Text(
                  'Used Rewards',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...entry.usedRewards.map(
                  (u) => ListTile(
                    leading: const Icon(Icons.timer, color: Colors.amber),
                    title: Text(u.rewardName),
                    subtitle: Text('${u.startedAt} → ${u.finishedAt}'),
                    trailing: Text('${u.durationMinutes} min'),
                  ),
                ),
              ],
              if (entry.completedTasks.isEmpty && entry.usedRewards.isEmpty)
                Center(child: Text('No activity for this day')),
            ],
          ),
        ),
      ),
    );
  }
}
