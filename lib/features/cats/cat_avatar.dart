import 'dart:io';

import 'package:flutter/material.dart';

/// Circular cat profile image. Falls back to a paw icon when no photo has
/// been set, or the stored file is missing.
class CatAvatar extends StatelessWidget {
  const CatAvatar({super.key, this.photoPath, this.radius = 24});

  final String? photoPath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(path)),
      );
    }
    return CircleAvatar(
      radius: radius,
      child: Icon(Icons.pets, size: radius),
    );
  }
}
