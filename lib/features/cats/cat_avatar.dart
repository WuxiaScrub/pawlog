import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Circular cat profile image. Falls back to a paw icon when no photo has
/// been set, or the stored file is missing. [photoPath] is either a native
/// file path or, on web, a base64 data URL (see PhotoStorage).
class CatAvatar extends StatelessWidget {
  const CatAvatar({super.key, this.photoPath, this.radius = 24});

  final String? photoPath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = _resolveImage();
    if (image != null) {
      return CircleAvatar(radius: radius, backgroundImage: image);
    }
    return CircleAvatar(
      radius: radius,
      child: Icon(Icons.pets, size: radius),
    );
  }

  ImageProvider? _resolveImage() {
    final path = photoPath;
    if (path == null || path.isEmpty) return null;

    if (path.startsWith('data:')) {
      final base64Data = path.substring(path.indexOf(',') + 1);
      return MemoryImage(base64Decode(base64Data));
    }

    if (kIsWeb) return null;
    return File(path).existsSync() ? FileImage(File(path)) : null;
  }
}
