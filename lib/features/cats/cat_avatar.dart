import 'package:flutter/material.dart';

import '../../core/local_photo.dart';

/// Circular cat profile image. Falls back to a paw icon when no photo has
/// been set, or the stored file is missing. [photoPath] is either a native
/// file path or, on web, a base64 data URL (see PhotoStorage).
class CatAvatar extends StatelessWidget {
  const CatAvatar({super.key, this.photoPath, this.radius = 24});

  final String? photoPath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = resolveLocalPhoto(photoPath);
    if (image != null) {
      return CircleAvatar(radius: radius, backgroundImage: image);
    }
    return CircleAvatar(
      radius: radius,
      child: Icon(Icons.pets, size: radius),
    );
  }
}
