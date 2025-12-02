import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/category_xp.dart';
import '../services/category_xp_repository.dart';

class CategoryXpBar extends StatelessWidget {
  final TaskCategory category;
  final CategoryXp? stats;

  const CategoryXpBar({Key? key, required this.category, this.stats})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryStats = stats;
    if (categoryStats == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                Task.getCategoryLabel(category),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Level 1 (0 XP)',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final xpForNext = CategoryXpRepository().xpForNextLevelOf(categoryStats);
    final progress = categoryStats.totalXp / xpForNext;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              Task.getCategoryLabel(category),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation(Colors.amber),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Level ${categoryStats.level} (${categoryStats.totalXp}/$xpForNext XP)',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
