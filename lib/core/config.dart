/// Application configuration
/// This file contains all environment-specific configurations
class AppConfig {
  // Chat Service Configuration
  static const String chatServiceUrl = String.fromEnvironment(
    'CHAT_SERVICE_URL',
    defaultValue: 'http://192.168.29.246:8000', // Your computer's IP for USB debugging
  );

  // Production URLs
  static const String productionChatUrl = 'https://your-chat-service.com'; // Replace with your actual URL

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eivjgwxyijhfmnyrcbcb.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Google Maps API Configuration
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyD5ZG8yheuA88UsmYT0fs2Xst5-75tyqKQ',
  );

  // Razorpay Configuration
  static const String razorpayTestKey = String.fromEnvironment(
    'RAZORPAY_TEST_KEY',
    defaultValue: 'rzp_test_RvNP7q1DMTG2fT',
  );

  static const String razorpayTestSecret = String.fromEnvironment(
    'RAZORPAY_TEST_SECRET',
    defaultValue: 'Eof7W6tuZmf65nVz623Cipzp',
  );

  static const String razorpayEnvironment = String.fromEnvironment(
    'RAZORPAY_ENVIRONMENT',
    defaultValue: 'test',
  );

  // Get the active Razorpay key based on environment
  static String get razorpayKey {
    if (razorpayEnvironment == 'live') {
      // For production, you would add RAZORPAY_LIVE_KEY environment variable
      return String.fromEnvironment(
        'RAZORPAY_LIVE_KEY',
        defaultValue: razorpayTestKey, // Fallback to test key if live not configured
      );
    }
    return razorpayTestKey;
  }

  // Environment detection
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;

  // Get the appropriate chat service URL based on environment
  static String get activeChatServiceUrl {
    if (isProduction) {
      // In production, use the production URL
      return productionChatUrl;
    }
    return chatServiceUrl;
  }

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration chatTimeout = Duration(seconds: 20);

  // Retry Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Feature Flags
  static const bool enableChatHistory = true;
  static const bool enableVoiceEscalation = false; // Set to true when Twilio is configured
  static const bool enableOfflineMode = true;

  // Logging
  static bool get enableLogging => isDevelopment;

  // Validate configuration
  static bool validateConfig() {
    if (isProduction) {
      // In production, ensure critical configs are set
      if (productionChatUrl.contains('your-chat-service')) {
        throw Exception('Production chat URL not configured!');
      }
      if (supabaseAnonKey.isEmpty) {
        throw Exception('Supabase anon key not configured!');
      }
    }
    return true;
  }
}
