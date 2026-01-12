import 'package:flutter/material.dart';

class TopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final String? title;
  final VoidCallback? onUserTap;
  final VoidCallback? onShopTap;
  final bool userSelected;
  final bool shopSelected;

  const TopNavbar({
    Key? key,
    this.currentIndex = 0,
    this.onTap,
    this.title,
    this.onUserTap,
    this.onShopTap,
    this.userSelected = false,
    this.shopSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2d1b3d), // Dark purple matching Home Screen
              const Color(0xFF1a1625), // Dark background matching Home Screen
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.person,
          color: userSelected ? Colors.amber.shade300 : Colors.grey.shade400,
          size: 26,
        ),
        tooltip: 'Profile',
        splashColor: Colors.amber.shade700.withOpacity(0.3),
        highlightColor: Colors.amber.shade800.withOpacity(0.2),
        onPressed: () {
          if (onUserTap != null) return onUserTap!();
          if (onTap != null) return onTap!(0);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.shopping_bag,
            color: shopSelected ? Colors.amber.shade300 : Colors.grey.shade400,
            size: 26,
          ),
          tooltip: 'Shop',
          splashColor: Colors.amber.shade700.withOpacity(0.3),
          highlightColor: Colors.amber.shade800.withOpacity(0.2),
          onPressed: () {
            if (onShopTap != null) return onShopTap!();
            if (onTap != null) return onTap!(1);
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
