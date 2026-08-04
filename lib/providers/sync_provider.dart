import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sync_service.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(databaseProvider));
});

final syncStatusProvider = StreamProvider<SyncResult>((ref) {
  return ref.watch(syncServiceProvider).statusStream;
});

final autoSyncProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    final sync = ref.read(syncServiceProvider);
    unawaited(sync.initializeForUser(user.id));
  }
});
