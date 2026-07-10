import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/claude_service.dart';
import '../core/stt_service.dart';
import '../core/tts_service.dart';

const _apiKeyKey = 'anthropic_api_key';
const _storage = FlutterSecureStorage();

final apiKeyProvider = FutureProvider<String?>((ref) async {
  return _storage.read(key: _apiKeyKey);
});

Future<void> saveApiKey(String key) async {
  await _storage.write(key: _apiKeyKey, value: key);
}

Future<void> deleteApiKey() async {
  await _storage.delete(key: _apiKeyKey);
}

final claudeServiceProvider = Provider<ClaudeService?>((ref) {
  final keyAsync = ref.watch(apiKeyProvider);
  return keyAsync.whenOrNull(data: (key) {
    if (key == null || key.isEmpty) return null;
    return ClaudeService(key);
  });
});

final sttServiceProvider = Provider<SttService>((ref) {
  return SttService();
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});
