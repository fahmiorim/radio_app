import 'package:flutter_dotenv/flutter_dotenv.dart';

String _readEnv(String key) {
  final defined = const String.fromEnvironment(key);
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

  static String get authEndpoint {
    final raw = _readOptional('PUSHER_AUTH_ENDPOINT');
    if (raw.isEmpty) {
      return 'https://odanfm.batubarakab.go.id/api/broadcasting/auth';
    }
    if (raw.startsWith('http')) return raw;
    return 'https://odanfm.batubarakab.go.id${raw.startsWith('/') ? raw : '/$raw'}';
  }
}

String _readOptional(String key) {
  final defined = const String.fromEnvironment(key);
  if (defined.isNotEmpty) return defined.trim();
  return dotenv.maybeGet(key)?.trim() ?? '';
}
