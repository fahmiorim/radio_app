import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _tokenKey = 'user_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  // Get current auth token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Save auth token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Clear auth data (logout)
  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }
}
