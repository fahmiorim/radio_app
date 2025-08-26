import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppApiConfig {
  static late final String baseUrl;

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
      baseUrl = _getEnv('BASE_URL');
    } catch (e) {
      print('Error initializing AppApiConfig: $e');
      rethrow;
    }
  }

  static String _getEnv(String key) {
    // First try environment variables
    final env = String.fromEnvironment(key);
    if (env.isNotEmpty) return env;

    // Then try .env file
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Environment variable $key is not set');
    }
    return value;
  }
}
