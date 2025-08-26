import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppApiConfig {
  static late final String baseUrl;
  static late final String baseUrlStorage;

  /// Initialize environment variables
  static Future<void> init() async {
    try {
      // Load .env file if not already loaded
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: '.env');
      }
      
      // Initialize the URLs
      baseUrl = _getEnv('BASE_URL');
      baseUrlStorage = _getEnv('BASE_URL_STORAGE');
    } catch (e) {
      print('Error initializing AppApiConfig: $e');
      rethrow;
    }
  }

  static String _getEnv(String key) {
    // First try from environment
    final envValue = String.fromEnvironment(key);
    if (envValue.isNotEmpty) return envValue;

    // Then try from .env file
    final fileValue = dotenv.maybeGet(key);
    if (fileValue != null && fileValue.isNotEmpty) return fileValue;

    throw StateError(
      '$key is not set. Provide it via --dart-define or in a .env file.',
    );
  }
}
