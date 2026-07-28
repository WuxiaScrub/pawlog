import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://mskleaccccsepvpzatnp.supabase.co';
const _supabaseAnonKey = 'sb_publishable_N3NdbLJXRqXJNv-IEFO1pQ_p5t8bON4';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
