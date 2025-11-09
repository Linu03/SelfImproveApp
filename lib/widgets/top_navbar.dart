import 'package:flutter/material.dart';

class TopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final String? title;
  final VoidCallback? onUserTap;
  final VoidCallback? onShopTap;

  const TopNavbar({
    Key? key,
    this.currentIndex = 0,
    this.onTap,
    this.title,
    this.onUserTap,
    this.onShopTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue,
      elevation: 4,
      leading: IconButton(
        icon: const Icon(Icons.person),
        tooltip: 'Profile',
        onPressed: () {
          if (onUserTap != null) return onUserTap!();
          if (onTap != null) return onTap!(0);
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shop),
          tooltip: 'Shop',
          onPressed: () {
            if (onShopTap != null) return onShopTap!();
            if (onTap != null) return onTap!(1);
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
