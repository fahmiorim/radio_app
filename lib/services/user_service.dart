import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import '../models/user_model.dart';
import '../config/logger.dart';

class UserService {
  static const String _userKey = 'user_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final Dio _dio = ApiClient.dio;

  /// Ambil token dari secure storage
  static Future<String?> _getToken() async {
    return await _storage.read(key: _userKey);
  }

  /// Simpan token setelah login
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _userKey, value: token);
  }

  /// Hapus token saat logout
  static Future<void> clearToken() async {
    await _storage.delete(key: _userKey);
  }

  /// Logout dari API dan hapus token lokal
  static Future<void> logout() async {
    try {
      final token = await _getToken();
      if (token != null) {
        await _dio.post(
          '/logout',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
        );
      }
    } catch (e) {
      logger.e('Error during logout: $e');
    } finally {
      await clearToken();
    }
  }

  /// Get user profile
  static Future<UserModel?> getProfile() async {
    try {
      final token = await _getToken();
      if (token == null) {
        logger.w("⚠️ Token tidak ada, user belum login.");
        return null;
      }

      final response = await _dio.get(
        '/user',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final body = response.data;

        if (body['status'] == true && body['data'] != null) {
          return UserModel.fromJson(body['data']);
        } else {
          logger.w("API status false: $body");
        }
      } else {
        logger.e("Request gagal: ${response.statusCode} ${response.data}");
      }
      return null;
    } catch (e) {
      logger.e('Error fetching user profile: $e');
      return null;
    }
  }
}
