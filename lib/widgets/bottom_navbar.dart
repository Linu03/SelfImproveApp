import 'package:flutter/material.dart';

/// Custom bottom navigation bar that allows a nullable [currentIndex].
/// If [currentIndex] is null the bar is shown but no item is highlighted.
class BottomNavbar extends StatelessWidget {
  final int? currentIndex;
  final ValueChanged<int>? onTap;

  const BottomNavbar({Key? key, this.currentIndex, this.onTap})
    : super(key: key);

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final bool selected = currentIndex != null && currentIndex == index;
    final color = selected ? Colors.amber : Colors.white70;
    return Expanded(
      child: IconButton(
        icon: Icon(icon, color: color),
        tooltip: label,
        onPressed: () => onTap?.call(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [Color.fromARGB(255, 20, 93, 154), Colors.indigo],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildItem(context, Icons.home, 'Home', 0),
            _buildItem(context, Icons.add_task, 'Add Task', 1),
            _buildItem(context, Icons.book, 'Journal', 2),
          ],
        ),
      ),
    );
  }
}
