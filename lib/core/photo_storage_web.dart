import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import 'photo_cloud.dart';

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
    final ext = p.extension(picked.name).isEmpty ? '.jpg' : p.extension(picked.name);

    final cloudUrl = await uploadPhotoToCloud(bytes, ext);
    if (cloudUrl != null) return cloudUrl;

    final mimeType = picked.mimeType ?? 'image/jpeg';
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  Future<void> delete(String? photoPath) async {
    await deleteCloudPhoto(photoPath);
  }
}
