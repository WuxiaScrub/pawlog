import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications_service.dart';
import 'core/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    initSupabase(),
    NotificationsService.initializeTimezone(),
  ]);
  runApp(const ProviderScope(child: PawLogApp()));
}
