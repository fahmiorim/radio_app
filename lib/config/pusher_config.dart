import 'package:flutter_dotenv/flutter_dotenv.dart';

class PusherConfig {
  static String get appKey {
    final key = dotenv.maybeGet('PUSHER_APP_KEY')?.trim();
    if (key == null || key.isEmpty) {
      throw Exception('PUSHER_APP_KEY tidak ditemukan di .env');
    }
    return key;
  }

  static String get cluster {
    final cluster = dotenv.maybeGet('PUSHER_CLUSTER')?.trim();
    if (cluster == null || cluster.isEmpty) {
      throw Exception('PUSHER_CLUSTER tidak ditemukan di .env');
    }
    return cluster;
  }

  static String get authEndpoint {
    final raw = (dotenv.maybeGet('PUSHER_AUTH_ENDPOINT') ?? '').trim();
    if (raw.isEmpty) {
      return 'https://odanfm.batubarakab.go.id/api/broadcasting/auth';
    }
    if (raw.startsWith('http')) return raw;
    return 'https://odanfm.batubarakab.go.id${raw.startsWith('/') ? raw : '/$raw'}';
  }
}
