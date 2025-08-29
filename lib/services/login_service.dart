import 'package:dio/dio.dart';
import 'package:radio_odan_app/config/api_client.dart';
import 'package:radio_odan_app/models/login_model.dart';
import 'package:radio_odan_app/services/user_service.dart';
import 'package:radio_odan_app/config/logger.dart';

class AuthService {
  final Dio _dio = ApiClient.I.dio;

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
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'password_confirmation': password,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Check if response.data is a Map and contains the expected fields
        if (response.data is Map && response.data['token'] != null) {
          final auth = AuthResponse.fromJson(response.data);
          if (auth.token.isNotEmpty) {
            await UserService.saveToken(auth.token);
          }
          return auth;
        } else {
          // If no token in response but registration was successful
          logger.i('Registration successful but no token received');
          return AuthResponse(
            token: '',
            user: UserModel(id: 0, name: name, email: email),
          );
        }
      } else {
        final errorMessage =
            response.data is Map && response.data['message'] != null
            ? response.data['message']
            : 'Registrasi gagal';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      String errorMessage = 'Gagal melakukan registrasi';

      if (e.response?.statusCode == 422) {
        final respData = e.response?.data;
        // Handle validation errors
        if (respData is Map && respData['errors'] != null) {
          final errors = respData['errors'] as Map<String, dynamic>;
          errorMessage = errors.values.first?.first?.toString() ?? errorMessage;
        } else if (respData is Map && respData['message'] != null) {
          errorMessage = respData['message'];
        }
      } else if (e.response?.data is String) {
        errorMessage = e.response?.data;
      }

      logger.e('Register error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      logger.e('Register error: $e');
      throw Exception('Terjadi kesalahan saat registrasi');
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
