import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:radio_odan_app/config/api_client.dart';
import 'package:radio_odan_app/models/user_model.dart';

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

  // ===================== Email/Password =====================
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
      ApiClient.I.setBearer(token);

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

  Future<AuthResult> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final res = await ApiClient.I.dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
        options: Options(
          extra: {'noAuth': true},
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (c) => c != null && c < 500,
        ),
      );

      final data = res.data as Map<String, dynamic>? ?? {};

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          (data['status'] == true || data['token'] != null)) {
        final token = (data['token'] ?? '').toString();
        if (token.isEmpty) {
          return const AuthResult(
            status: false,
            message: 'Token tidak ditemukan setelah registrasi.',
          );
        }

        await _storage.write(key: 'user_token', value: token);
        ApiClient.I.setBearer(token);

        final userJson = (data['user'] ?? {}) as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson);

        return AuthResult(
          status: true,
          message: data['message']?.toString() ?? 'Pendaftaran akun berhasil.',
          token: token,
          user: user,
        );
      }

      if ((res.statusCode == 200 || res.statusCode == 201)) {
        if (data['token'] != null) {
          return AuthResult(
            status: true,
            message: data['message']?.toString() ?? 'Pendaftaran berhasil',
            token: data['token'].toString(),
            user: data['user'] != null
                ? UserModel.fromJson(data['user'])
                : null,
          );
        }
        return AuthResult(
          status: false,
          message: 'Registrasi berhasil tetapi token tidak ditemukan',
        );
      }

      return AuthResult(
        status: false,
        message:
            _messageFromResponseMap(data) ??
            'Registrasi gagal. (HTTP ${res.statusCode})',
      );
    } on DioException catch (e) {
      return AuthResult(
        status: false,
        message: _extractApiError(e, 'Gagal registrasi.'),
      );
    }
  }

  // ===================== Firebase Auth ======================
  Future<String> _getFirebaseIdToken(fb.User user) async {
    final String? t1 = await user.getIdToken(true); // force refresh
    if (t1 != null && t1.isNotEmpty) return t1;

    final String? t2 = await user.getIdToken(false); // cached
    if (t2 != null && t2.isNotEmpty) return t2;

    throw StateError('Firebase mengembalikan token kosong.');
  }

  Future<AuthResult> loginWithIdToken({
    required String idToken,
    String? name,
    String? email,
    String? photoUrl,
  }) async {
    try {
      final res = await ApiClient.I.dio.post(
        '/firebase-login',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (photoUrl != null) 'photo_url': photoUrl,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (c) => c != null && c >= 200 && c < 500,
        ),
      );

      final data = res.data as Map<String, dynamic>? ?? {};
      if (res.statusCode == 200 && data['status'] == true) {
        final token = (data['token'] ?? '').toString();
        if (token.isEmpty) {
          return const AuthResult(
            status: false,
            message: 'JWT kosong dari server.',
          );
        }

        await _storage.write(key: 'user_token', value: token);
        ApiClient.I.setBearer(token);

        final userJson = (data['data'] ?? {}) as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson);

        return AuthResult(
          status: true,
          message: data['message']?.toString() ?? 'Login berhasil.',
          token: token,
          user: user,
        );
      }

      return AuthResult(
        status: false,
        message:
            (data['message']?.toString() ??
            'Login Firebase gagal. (HTTP ${res.statusCode})'),
      );
    } on DioException catch (e) {
      return AuthResult(
        status: false,
        message: _extractApiError(e, 'Gagal login via Firebase.'),
      );
    }
  }

  Future<AuthResult> loginWithFirebaseUser(fb.User user) async {
    final idToken = await _getFirebaseIdToken(user);
    return loginWithIdToken(
      idToken: idToken,
      name: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
    // NOTE: ApiClient.I.setBearer(token) dilakukan di loginWithIdToken()
  }

  // ===================== Misc ======================
  Future<bool> checkEmailVerified() async {
    try {
      final res = await ApiClient.I.dio.get('/user');
      final data = res.data as Map<String, dynamic>? ?? {};
      final userData = (data['data'] ?? {}) as Map<String, dynamic>;
      return userData['email_verified_at'] != null;
    } catch (_) {
      return false;
    }
  }

  Future<String?> resendVerificationEmail() async {
    try {
      final response = await ApiClient.I.dio.post(
        '/email/verification-notification',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        return null; // Success
      }

      // Handle rate limiting (status code 429)
      if (response.statusCode == 429) {
        final retryAfter = response.headers['retry-after']?.first;
        final waitTime = retryAfter != null
            ? 'Coba lagi dalam $retryAfter detik'
            : 'beberapa saat lagi';
        return 'Terlalu banyak permintaan. $waitTime';
      }

      // Handle other errors
      final errorData = response.data as Map<String, dynamic>?;
      return errorData?['message']?.toString() ??
          'Gagal mengirim ulang email verifikasi';
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final retryAfter = e.response?.headers['retry-after']?.first;
        final waitTime = retryAfter != null
            ? 'Coba lagi dalam $retryAfter detik'
            : 'beberapa saat lagi';
        return 'Terlalu banyak permintaan. $waitTime';
      }
      return _extractApiError(e, 'Gagal mengirim ulang email verifikasi.');
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      final res = await ApiClient.I.dio.post(
        '/forgot-password',
        data: {'email': email},
      );
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

  Future<String?> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
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

  static Future<bool> isLoggedIn() async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'user_token');
      return (token ?? '').isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // optional: await ApiClient.I.dio.post('/logout');
    } finally {
      await _storage.delete(key: 'user_token');
      ApiClient.I.clearBearer();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final res = await ApiClient.I.dio.get('/user');
      final data = res.data as Map<String, dynamic>? ?? {};
      if (data['user'] == null) return null;
      return UserModel.fromJson(data['user']);
    } catch (_) {
      return null;
    }
  }

  String _extractApiError(DioException e, String fallback) {
    try {
      if (e.response?.data is Map) {
        return e.response?.data['message'] ?? fallback;
      }
      if (e.response?.data is String) {
        return e.response?.data ?? fallback;
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  String? _messageFromResponseMap(Map<String, dynamic>? data) {
    if (data == null) return null;

    // Check for common error message fields in the response
    if (data['message'] != null) return data['message'].toString();
    if (data['error'] != null) return data['error'].toString();
    if (data['errors'] != null) {
      // Handle errors object that might contain field-specific errors
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          // Return the first error message
          final firstError = errors.values.first;
          if (firstError is List) {
            return firstError.first.toString();
          }
          return firstError.toString();
        }
      }
      return data['errors'].toString();
    }

    return null;
  }
}
