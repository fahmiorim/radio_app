import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:radio_odan_app/config/api_client.dart';
import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/config/logger.dart';

class UserService {
  static const String _userKey = 'user_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: _userKey);
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _userKey, value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _userKey);
  }

  static Future<UserModel?> getProfile() async {
    try {
      final response = await ApiClient.dio.get('/user');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['status'] == true && body['data'] != null) {
          return UserModel.fromJson(body['data']);
        }
      }
      return null;
    } catch (e) {
      logger.e("Error getProfile: $e");
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      await ApiClient.dio.post('/logout');
    } catch (e) {
      logger.w("Logout error: $e");
    } finally {
      await clearToken();
    }
  }
}
