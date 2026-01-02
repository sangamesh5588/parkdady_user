import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _supabaseUrlKey = 'SUPABASE_URL';
  static const String _supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';

  static String get supabaseUrl => _getValue(_supabaseUrlKey);
  static String get supabaseAnonKey => _getValue(_supabaseAnonKeyKey);

  static String _getValue(String key) {
    try {
      final value = dotenv.get(key);
      if (value.isEmpty) {
        throw Exception('Environment variable $key is empty');
      }
      return value;
    } catch (e) {
      throw Exception('Required environment variable $key not found. Please check your .env file.');
    }
  }

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');

      final url = supabaseUrl;
      final anonKey = supabaseAnonKey;

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        debug: true,
      );
      print('✅ Supabase initialized successfully');
    } catch (e) {
      print('❌ Supabase initialization failed: $e');
      rethrow;
    }
  }

  // Get client - should always be available if initialized successfully
  static SupabaseClient get client => Supabase.instance.client;
}
