import 'package:flutter_dotenv/flutter_dotenv.dart';

String _readEnv(String key) {
  final defined = String.fromEnvironment(key);
  if (defined.isNotEmpty) return defined.trim();
  final value = dotenv.maybeGet(key)?.trim();
  if (value == null || value.isEmpty) {
    throw Exception('$key tidak ditemukan di konfigurasi');
  }
  return value;
}

class PusherConfig {
  static String get appKey => _readEnv('PUSHER_APP_KEY');

  static String get cluster => _readEnv('PUSHER_CLUSTER');

  static String get authEndpoint => _readEnv('PUSHER_AUTH_ENDPOINT');
}
