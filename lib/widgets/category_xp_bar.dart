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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF2d1b3d), const Color(0xFF1f1529)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.purple.shade700.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.shade900.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                Task.getCategoryLabel(category),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade200,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade800,
                valueColor: AlwaysStoppedAnimation(Colors.amber.shade400),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Level 1 (0 XP)',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final xpForNext = CategoryXpRepository().xpForNextLevelOf(categoryStats);
    final progress = categoryStats.totalXp / xpForNext;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2d1b3d), const Color(0xFF1f1529)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.shade700.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade900.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              Task.getCategoryLabel(category),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade200,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation(Colors.amber.shade400),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Level ${categoryStats.level} (${categoryStats.totalXp}/$xpForNext XP)',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
