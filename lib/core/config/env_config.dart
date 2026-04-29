import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl => _read('SUPABASE_URL');
  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY');
  static String get supabaseStorageBucket =>
      _read('SUPABASE_STORAGE_BUCKET', fallback: 'artflow-media');
  static String get supabaseProfileFolder =>
      _read('SUPABASE_PROFILE_FOLDER', fallback: 'profiles');
  static String get supabaseArtworkFolder =>
      _read('SUPABASE_ARTWORK_FOLDER', fallback: 'artworks');
  static String get supabaseArtistApplicationFolder => _read(
    'SUPABASE_ARTIST_APPLICATION_FOLDER',
    fallback: 'artist-applications',
  );
  static String get supabaseScholarFolder =>
      _read('SUPABASE_SCHOLAR_FOLDER', fallback: 'scholar-verifications');

  static bool get hasSupabaseConfig =>
      _isConfiguredValue(supabaseUrl) && _isConfiguredValue(supabaseAnonKey);

  static String _read(String key, {String fallback = ''}) {
    if (!dotenv.isInitialized) {
      return fallback;
    }
    final value = dotenv.env[key]?.trim() ?? '';
    if (value.isEmpty) {
      return fallback;
    }
    return value;
  }

  static bool _isConfiguredValue(String value) {
    if (value.isEmpty) {
      return false;
    }
    return !value.startsWith('YOUR_');
  }
}
