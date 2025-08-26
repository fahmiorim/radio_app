import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_api_config.dart';
import '../models/user_model.dart';
import '../config/logger.dart';

class UserService {
  static const String _userKey = 'user_token';

  // Ambil token dari SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  // Simpan token setelah login
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, token);
  }

  // Hapus token saat logout
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Get user profile
  static Future<UserModel?> getProfile() async {
    try {
      final token = await _getToken();
      if (token == null) {
        logger.w("Token tidak ada, user belum login.");
        return null;
      }

      final response = await http.get(
        Uri.parse('${AppApiConfig.baseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['status'] == true && body['data'] != null) {
          // ✅ Ambil langsung object "data"
          return UserModel.fromJson(body['data']);
        } else {
          logger.w("API status false: ${response.body}");
        }
      } else {
        logger.e("Request gagal: ${response.statusCode} ${response.body}");
      }
      return null;
    } catch (e) {
      logger.e('Error fetching user profile: $e');
      return null;
    }
  }
}
