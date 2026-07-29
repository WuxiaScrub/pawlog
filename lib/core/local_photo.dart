import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Resolves a path produced by [PhotoStorage] into an [ImageProvider].
/// Handles cloud URLs, base64 data URLs, and native file paths.
/// Returns null if there's nothing to show.
ImageProvider? resolveLocalPhoto(String? path) {
  if (path == null || path.isEmpty) return null;

  if (path.startsWith('https://') || path.startsWith('http://')) {
    return NetworkImage(path);
  }

  if (path.startsWith('data:')) {
    final base64Data = path.substring(path.indexOf(',') + 1);
    return MemoryImage(base64Decode(base64Data));
  }

  if (kIsWeb) return null;
  return File(path).existsSync() ? FileImage(File(path)) : null;
}
