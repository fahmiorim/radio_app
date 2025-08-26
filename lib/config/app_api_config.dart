import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppApiConfig {
  /// Base URL for API requests. Must be provided via
  /// `--dart-define=BASE_URL=your_url` at build time or in a `.env` file.
  static final String baseUrl = _getEnv('BASE_URL');

  /// Base URL for storage. Must be provided via
  /// `--dart-define=BASE_URL_STORAGE=your_url` at build time or in a `.env` file.
  static final String baseUrlStorage = _getEnv('BASE_URL_STORAGE');

  static String _getEnv(String key) {
    const envValue = String.fromEnvironment(key);
    if (envValue.isNotEmpty) return envValue;

    final fileValue = dotenv.maybeGet(key);
    if (fileValue != null && fileValue.isNotEmpty) return fileValue;

    throw StateError(
      '$key is not set. Provide it via --dart-define or in a .env file.',
    );
  }
}
