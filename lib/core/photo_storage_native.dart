import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Handles picking a cat profile photo and copying it into app-local
/// storage so it survives independent of wherever the OS picker sourced it
/// from (camera roll, cloud-backed photo, etc).
class PhotoStorage {
  const PhotoStorage();

  static const _uuid = Uuid();

  Future<String?> pickAndSave({required ImageSource source}) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'cat_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final ext = p.extension(picked.path);
    final fileName = '${_uuid.v4()}$ext';
    final savedPath = p.join(photosDir.path, fileName);
    await File(picked.path).copy(savedPath);
    return savedPath;
  }

  Future<void> delete(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return;
    final file = File(photoPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
