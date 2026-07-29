import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'photo_cloud.dart';

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

    final bytes = await picked.readAsBytes();
    final ext = p.extension(picked.path);

    final cloudUrl = await uploadPhotoToCloud(bytes, ext);
    if (cloudUrl != null) return cloudUrl;

    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final fileName = '${_uuid.v4()}$ext';
    final savedPath = p.join(photosDir.path, fileName);
    await File(picked.path).copy(savedPath);
    return savedPath;
  }

  Future<void> delete(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return;

    await deleteCloudPhoto(photoPath);

    if (!photoPath.startsWith('http')) {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
