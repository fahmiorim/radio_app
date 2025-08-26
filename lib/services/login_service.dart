import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_api_config.dart';
import '../models/login_model.dart';
import '../services/user_service.dart'; // ✅ biar bisa saveToken
import '../config/logger.dart';

class AuthService {
  /// Login dengan email & password
  Future<AuthResponse?> login(String email, String password) async {
    try {
      final baseUrl = AppApiConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final auth = AuthResponse.fromJson(data);

        await UserService.saveToken(auth.token);
        return auth;
      } else {
        final data = jsonDecode(response.body);
        final errorMessage =
            data['message'] ??
            (data['errors']?.values.first.first ?? 'Login gagal');
        throw Exception(errorMessage); // lempar ke UI
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  /// Register user baru
  Future<AuthResponse?> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final baseUrl = AppApiConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        body: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final auth = AuthResponse.fromJson(data);

        // ✅ simpan token juga kalau API balikin token
        if (auth.token.isNotEmpty) {
          await UserService.saveToken(auth.token);
        }

        return auth;
      } else {
        logger.w('Registrasi gagal: ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Error AuthService register: $e');
      return null;
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    try {
      final baseUrl = AppApiConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        body: {'email': email},
      );

      return response.statusCode == 200;
    } catch (e) {
      logger.e('Error AuthService forgotPassword: $e');
      return false;
    }
  }

  /// Login dengan Google
  Future<AuthResponse?> loginWithGoogle(String idToken) async {
    try {
      final baseUrl = AppApiConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/login/google'),
        body: {'token': idToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final auth = AuthResponse.fromJson(data);

        // ✅ simpan token
        await UserService.saveToken(auth.token);

        return auth;
      } else {
        logger.w('Login Google gagal: ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Error AuthService loginWithGoogle: $e');
      return null;
    }
  }
}
