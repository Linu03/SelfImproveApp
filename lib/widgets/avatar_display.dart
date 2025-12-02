import 'package:flutter/material.dart';
import 'dart:typed_data';

class AvatarDisplay extends StatelessWidget {
  final List<int>? avatarBytes;
  final double radius;
  final Color? borderColor;
  final double? borderWidth;

  const AvatarDisplay({
    Key? key,
    this.avatarBytes,
    this.radius = 50,
    this.borderColor,
    this.borderWidth = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(
                color: borderColor!,
                width: borderWidth ?? 3,
              )
            : null,
        gradient: avatarBytes == null
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.fromARGB(255, 20, 93, 154), Colors.indigo],
              )
            : null,
      ),
      child: avatarBytes != null && avatarBytes!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.memory(
                Uint8List.fromList(avatarBytes!),
                fit: BoxFit.cover,
              ),
            )
          : Center(
              child: Icon(
                Icons.person,
                size: radius * 0.8,
                color: Colors.white,
              ),
            ),
    );
  }
}
