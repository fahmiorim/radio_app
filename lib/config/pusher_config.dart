import 'package:flutter_dotenv/flutter_dotenv.dart';

class PusherConfig {
  static String get appKey {
    final key = dotenv.maybeGet('PUSHER_APP_KEY');
    if (key == null || key.isEmpty) {
      throw Exception('PUSHER_APP_KEY tidak ditemukan di .env');
    }
    return key;
  }

  static String get cluster {
    final cluster = dotenv.maybeGet('PUSHER_CLUSTER');
    if (cluster == null || cluster.isEmpty) {
      throw Exception('PUSHER_CLUSTER tidak ditemukan di .env');
    }
    return cluster;
  }

  static String get authEndpoint {
    final endpoint = dotenv.maybeGet('PUSHER_AUTH_ENDPOINT');
    if (endpoint == null || endpoint.isEmpty) {
      return '/broadcasting/auth';
    }
    return endpoint;
  }
}
