import 'package:dio/dio.dart';
import 'package:radio_odan_app/config/api_client.dart';
import 'package:radio_odan_app/models/login_model.dart';
import 'package:radio_odan_app/services/user_service.dart';
import 'package:radio_odan_app/config/logger.dart';

class AuthService {
  final Dio _dio = ApiClient.dio;

  Future<AuthResponse?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      final auth = AuthResponse.fromJson(response.data);
      await UserService.saveToken(auth.token);
      return auth;
    } on DioException catch (e) {
      String msg = 'Login gagal';
      final data = e.response?.data;

      if (data is Map<String, dynamic>) {
        msg = data['message'] ?? msg;
      } else if (data is String) {
        msg = data;
      }

      logger.e('Login error: $msg');
      throw Exception(msg);
    } catch (e) {
      logger.e('Login error: $e');
      throw Exception('Gagal login: $e');
    }
  }

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
        if (auth.token.isNotEmpty) {
          await UserService.saveToken(auth.token);
        }
        return auth;
      } else {
        throw Exception(response.data['message'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      logger.e("Register error: $e");
      throw Exception("Gagal registrasi: $e");
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/forgot-password',
        data: {'email': email},
      );
      return response.statusCode == 200;
    } catch (e) {
      logger.e("Forgot password error: $e");
      return false;
    }
  }

  Future<AuthResponse?> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post(
        '/login/google',
        data: {'token': idToken},
      );
      if (response.statusCode == 200) {
        final auth = AuthResponse.fromJson(response.data);
        await UserService.saveToken(auth.token);
        return auth;
      } else {
        throw Exception(response.data['message'] ?? 'Login Google gagal');
      }
    } catch (e) {
      logger.e("Login Google error: $e");
      throw Exception("Gagal login Google: $e");
    }
  }
}
