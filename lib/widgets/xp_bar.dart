import 'package:flutter/material.dart';

class XpBar extends StatelessWidget {
  final int currentXp;
  final int xpForNextLevel;
  final int level;

  const XpBar({
    Key? key,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.level,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = xpForNextLevel > 0
        ? (currentXp / xpForNextLevel).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Level $level',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LinearProgressIndicator(value: progress, minHeight: 12),
            ),
            const SizedBox(width: 12),
            Text('$currentXp / $xpForNextLevel'),
          ],
        ),
      ],
    );
  }
}
