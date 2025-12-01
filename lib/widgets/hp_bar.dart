import 'package:flutter/material.dart';

class HpBar extends StatelessWidget {
  final int currentHp;
  final int maxHp;

  const HpBar({Key? key, required this.currentHp, required this.maxHp})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0.0;
    final color = _getHealthColor(progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('HP', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(width: 12),
            Text('$currentHp / $maxHp'),
          ],
        ),
      ],
    );
  }

  Color _getHealthColor(double progress) {
    if (progress > 0.5) {
      return Colors.green;
    } else if (progress > 0.25) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
