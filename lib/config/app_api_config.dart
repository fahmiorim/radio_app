import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppApiConfig {
  static String get baseUrl {
    final url = dotenv.maybeGet('BASE_URL');
    if (url == null || url.isEmpty) {
      throw Exception("BASE_URL tidak ditemukan di .env");
    }
    return url;
  }
}
