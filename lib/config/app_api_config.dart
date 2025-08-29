import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppApiConfig {
  static String get apiBaseUrl {
    final url = dotenv.maybeGet('API_BASE_URL');
    if (url == null || url.isEmpty) {
      throw Exception("API_BASE_URL tidak ditemukan di .env");
    }
    return url;
  }

  static String get assetBaseUrl {
    final url = dotenv.maybeGet('ASSET_BASE_URL');
    if (url == null || url.isEmpty) {
      throw Exception("ASSET_BASE_URL tidak ditemukan di .env");
    }
    return url;
  }
}
