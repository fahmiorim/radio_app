import 'package:flutter_dotenv/flutter_dotenv.dart';

String _readEnv(String key) {
  final defined = String.fromEnvironment(key);
  if (defined.isNotEmpty) return defined;
  final value = dotenv.maybeGet(key);
  if (value == null || value.isEmpty) {
    throw Exception("$key tidak ditemukan di konfigurasi");
  }
  return value;
}

class AppApiConfig {
  static String get apiBaseUrl => _readEnv('API_BASE_URL');

  static String get assetBaseUrl => _readEnv('ASSET_BASE_URL');
}
