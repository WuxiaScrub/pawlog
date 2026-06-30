import 'dart:convert';

import 'package:image_picker/image_picker.dart';

/// Web counterpart to the native [PhotoStorage]. The browser has no
/// filesystem to copy a picked photo into (and `picked.path` is just a
/// transient blob: URL), so the image bytes are base64-encoded into a data
/// URL and stored directly in the `photoPath` column instead of a path.
class PhotoStorage {
  const PhotoStorage();

  Future<String?> pickAndSave({required ImageSource source}) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final mimeType = picked.mimeType ?? 'image/jpeg';
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  Future<void> delete(String? photoPath) async {
    // Nothing to clean up — data URLs live only in the database row.
  }
}
