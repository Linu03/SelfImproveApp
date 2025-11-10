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
      elevation: 4,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 20, 93, 154), Colors.indigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.person,
          color: userSelected ? Colors.amber : Colors.white,
        ),
        tooltip: 'Profile',
        onPressed: () {
          if (onUserTap != null) return onUserTap!();
          if (onTap != null) return onTap!(0);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.shopping_cart,
            color: shopSelected ? Colors.amber : Colors.white,
          ),
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
