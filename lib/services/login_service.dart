import 'package:dio/dio.dart';

import '../models/login_model.dart';
import 'api_client.dart';
import 'user_service.dart'; // ✅ biar bisa saveToken

class AuthService {
  final Dio _dio = ApiClient.dio;

  /// Login dengan email & password
  Future<AuthResponse?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final auth = AuthResponse.fromJson(response.data);

        await UserService.saveToken(auth.token);
        return auth;
      } else {
        final data = response.data;
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
      final response = await _dio.post(
        '/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final auth = AuthResponse.fromJson(response.data);

        // ✅ simpan token juga kalau API balikin token
        if (auth.token.isNotEmpty) {
          await UserService.saveToken(auth.token);
        }

        return auth;
      } else {
        print('Registrasi gagal: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Error AuthService register: $e');
      return null;
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/forgot-password',
        data: {'email': email},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error AuthService forgotPassword: $e');
      return false;
    }
  }

  /// Login dengan Google
  Future<AuthResponse?> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post(
        '/login/google',
        data: {'token': idToken},
      );

      if (response.statusCode == 200) {
        final auth = AuthResponse.fromJson(response.data);

        // ✅ simpan token
        await UserService.saveToken(auth.token);

        return auth;
      } else {
        print('Login Google gagal: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Error AuthService loginWithGoogle: $e');
      return null;
    }
  }
}
