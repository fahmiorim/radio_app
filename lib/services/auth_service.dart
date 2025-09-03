import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_client.dart';
import '../models/user_model.dart';

class AuthResult {
  final bool status;
  final String message;
  final String? token;
  final UserModel? user;

  const AuthResult({
    required this.status,
    required this.message,
    this.token,
    this.user,
  });
}

class AuthService {
  AuthService._();
  static final AuthService I = AuthService._();

  final _storage = const FlutterSecureStorage();

  /// LOGIN: POST /login
  Future<AuthResult> login(String email, String password) async {
    try {
      final res = await ApiClient.I.dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      final data = res.data as Map<String, dynamic>? ?? {};
      if (data['status'] != true) {
        return AuthResult(
          status: false,
          message: data['message']?.toString() ?? 'Login gagal.',
        );
      }

      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        return const AuthResult(
          status: false,
          message: 'Token tidak ditemukan.',
        );
      }

      await _storage.write(key: 'user_token', value: token);

      final userJson = (data['user'] ?? {}) as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      return AuthResult(
        status: true,
        message: data['message']?.toString() ?? 'Login berhasil.',
        token: token,
        user: user,
      );
    } on DioException catch (e) {
      return AuthResult(
        status: false,
        message: _extractApiError(e, 'Gagal login.'),
      );
    }
  }

  /// REGISTER: POST /register
  Future<AuthResult> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final res = await ApiClient.I.dio.post(
        '/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      final data = res.data as Map<String, dynamic>? ?? {};
      if (data['status'] != true) {
        return AuthResult(
          status: false,
          message: data['message']?.toString() ?? 'Registrasi gagal.',
        );
      }

      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        return const AuthResult(
          status: false,
          message: 'Token tidak ditemukan setelah registrasi.',
        );
      }

      await _storage.write(key: 'user_token', value: token);

      final userJson = (data['user'] ?? {}) as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      return AuthResult(
        status: true,
        message: data['message']?.toString() ?? 'Pendaftaran akun berhasil.',
        token: token,
        user: user,
      );
    } on DioException catch (e) {
      return AuthResult(
        status: false,
        message: _extractApiError(e, 'Gagal registrasi.'),
      );
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      final res = await ApiClient.I.dio.get('/me'); // sesuaikan: /me atau /user
      final data = res.data as Map<String, dynamic>? ?? {};
      final user = (data['user'] ?? {}) as Map<String, dynamic>;
      final verified = user['email_verified_at'] != null;
      return verified;
    } catch (_) {
      return false;
    }
  }

  Future<String?> resendVerificationEmail() async {
    try {
      // Laravel default: POST /email/verification-notification
      await ApiClient.I.dio.post('/email/verification-notification');
      return null; // null = sukses tanpa error
    } on DioException catch (e) {
      return _extractApiError(e, 'Gagal mengirim ulang email verifikasi.');
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      // Laravel Fortify default: POST /forgot-password
      final res = await ApiClient.I.dio.post(
        '/forgot-password',
        data: {'email': email},
      );

      // Banyak setup Laravel mengembalikan { status: "We have emailed your password reset link!" }
      final data = res.data;
      final ok =
          (data is Map && (data['status'] == true || data['status'] == 'OK')) ||
          res.statusCode == 200;

      if (ok) return null;
      return (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal mengirim email reset password.';
    } on DioException catch (e) {
      return _extractApiError(e, 'Gagal mengirim email reset password.');
    } catch (e) {
      return e.toString();
    }
  }

  /// Reset password dengan token dari email (opsional dipakai kalau reset di app)
  Future<String?> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      // Laravel Fortify default: POST /reset-password
      final res = await ApiClient.I.dio.post(
        '/reset-password',
        data: {
          'token': token,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      final data = res.data;
      final ok =
          (data is Map && (data['status'] == true || data['status'] == 'OK')) ||
          res.statusCode == 200;

      if (ok) return null;
      return (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal reset password.';
    } on DioException catch (e) {
      return _extractApiError(e, 'Gagal reset password.');
    } catch (e) {
      return e.toString();
    }
  }

  /// CEK LOGIN
  static Future<bool> isLoggedIn() async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'user_token');

      // Periksa apakah token ada dan valid
      if (token == null || token.isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      // Jika terjadi error, asumsikan tidak login
      return false;
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    try {
      // optional: hit endpoint logout kalau ada
      // await ApiClient.I.dio.post('/logout');
    } finally {
      await _storage.delete(key: 'user_token');
    }
  }

  /// Ambil user aktif (opsional, kalau API ada /me)
  Future<UserModel?> getCurrentUser() async {
    try {
      final res = await ApiClient.I.dio.get('/me');
      final data = res.data as Map<String, dynamic>? ?? {};
      if (data['user'] == null) return null;
      return UserModel.fromJson(data['user']);
    } catch (_) {
      return null;
    }
  }

  String _extractApiError(DioException e, String fallback) {
    try {
      final data = e.response?.data;
      if (data is Map && data['message'] != null)
        return data['message'].toString();
      if (data is String && data.isNotEmpty) return data;
    } catch (_) {}
    return fallback;
  }
}
