import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_client.dart';

const _uuid = Uuid();
const _bucket = 'cat-photos';

/// Uploads image bytes to Supabase Storage and returns the public URL.
/// Returns null if the user isn't logged in or the upload fails.
Future<String?> uploadPhotoToCloud(Uint8List bytes, String extension) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  final ext = extension.startsWith('.') ? extension : '.$extension';
  final fileName = '${_uuid.v4()}$ext';
  final path = '${user.id}/$fileName';

  final contentType = switch (ext.toLowerCase()) {
    '.png' => 'image/png',
    '.gif' => 'image/gif',
    '.webp' => 'image/webp',
    _ => 'image/jpeg',
  };

  try {
    await supabase.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return supabase.storage.from(_bucket).getPublicUrl(path);
  } catch (_) {
    return null;
  }
}

/// Deletes a cloud-hosted photo by its public URL. No-op for non-cloud paths.
Future<void> deleteCloudPhoto(String? url) async {
  if (url == null || !url.contains('/storage/v1/object/public/$_bucket/')) {
    return;
  }
  final storagePath =
      url.split('/storage/v1/object/public/$_bucket/').last;
  try {
    await supabase.storage.from(_bucket).remove([storagePath]);
  } catch (_) {
    // Best-effort cleanup.
  }
}
