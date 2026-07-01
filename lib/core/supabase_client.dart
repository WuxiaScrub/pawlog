import 'package:supabase_flutter/supabase_flutter.dart';

/// Cloud (premium-tier) backend config and client access.
///
/// Free-tier users never touch this — see `database.dart` for the
/// local-only Drift store every user starts on. Credentials are supplied
/// at build/run time via --dart-define so they never live in source
/// control:
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. Pass --dart-define=SUPABASE_URL=... '
        '--dart-define=SUPABASE_ANON_KEY=... when running/building.',
      );
    }
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}

SupabaseClient get supabase => Supabase.instance.client;
