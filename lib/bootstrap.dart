import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// True after [bootstrap] successfully calls [Supabase.initialize].
bool supabaseEnabled = false;

/// Loads env and initializes Supabase when URL and anon key are set.
Future<void> bootstrap() async {
  await dotenv.load(fileName: 'assets/env/.env');
  final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final key = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  if (url.isEmpty || key.isEmpty) {
    debugPrint(
      'Supabase not configured: set SUPABASE_URL and SUPABASE_ANON_KEY in assets/env/.env',
    );
    return;
  }
  await Supabase.initialize(url: url, anonKey: key);
  supabaseEnabled = true;
}
