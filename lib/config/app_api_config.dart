import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppApiConfig {
  static final String baseUrl = _getEnv('BASE_URL');

  static final String baseUrlStorage = _getEnv('BASE_URL_STORAGE');

  static String _getEnv(String key) {
    final envValue = String.fromEnvironment(key);
    if (envValue.isNotEmpty) return envValue;

    final fileValue = dotenv.maybeGet(key);
    if (fileValue != null && fileValue.isNotEmpty) return fileValue;

    throw StateError(
      '$key is not set. Provide it via --dart-define or in a .env file.',
    );
  }
}
