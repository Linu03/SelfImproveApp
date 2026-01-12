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
    final color = selected ? Colors.amber.shade300 : Colors.grey.shade500;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap?.call(index),
          splashColor: Colors.amber.shade700.withOpacity(0.3),
          highlightColor: Colors.amber.shade800.withOpacity(0.2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Active indicator
                if (selected)
                  Container(
                    width: 32,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade400,
                          Colors.amber.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.shade700.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 9),
                Icon(
                  icon,
                  color: color,
                  size: selected ? 28 : 24,
                  shadows: selected
                      ? [
                          Shadow(
                            color: Colors.amber.shade900.withOpacity(0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2d1b3d), // Dark purple matching Home Screen
            const Color(0xFF1a1625), // Dark background matching Home Screen
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          top: BorderSide(
            color: Colors.purple.shade900.withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildItem(context, Icons.home_rounded, 'Home', 0),
            _buildItem(context, Icons.add_circle_outline, 'Add Quest', 1),
            _buildItem(context, Icons.menu_book_rounded, 'Journal', 2),
          ],
        ),
      ),
    );
  }
}
