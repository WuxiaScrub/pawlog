import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Resolves a path produced by [PhotoStorage] — a native file path, or on
/// web a base64 data URL — into an [ImageProvider]. Returns null if there's
/// nothing to show.
ImageProvider? resolveLocalPhoto(String? path) {
  if (path == null || path.isEmpty) return null;

  if (path.startsWith('data:')) {
    final base64Data = path.substring(path.indexOf(',') + 1);
    return MemoryImage(base64Decode(base64Data));
  }

  if (kIsWeb) return null;
  return File(path).existsSync() ? FileImage(File(path)) : null;
}
