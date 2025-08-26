import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_api_config.dart';
import '../models/user_model.dart';

class UserService {
  static const String _userKey = 'user_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Ambil token dari secure storage
  static Future<String?> _getToken() async {
    return await _storage.read(key: _userKey);
  }

  // Simpan token setelah login
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _userKey, value: token);
  }

  // Hapus token saat logout
  static Future<void> clearToken() async {
    await _storage.delete(key: _userKey);
  }

  // Logout dari API dan hapus token lokal
  static Future<void> logout() async {
    try {
      final token = await _getToken();
      if (token != null) {
        await http.post(
          Uri.parse('${AppApiConfig.baseUrl}/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      await clearToken();
    }
  }

  // Get user profile
  static Future<UserModel?> getProfile() async {
    try {
      final token = await _getToken();
      if (token == null) {
        print("Token tidak ada, user belum login.");
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
          print("API status false: ${response.body}");
        }
      } else {
        print("Request gagal: ${response.statusCode} ${response.body}");
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
}
