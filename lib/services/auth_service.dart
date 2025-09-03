import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

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
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  AuthService._();
  static final AuthService I = AuthService._();

  final _storage = const FlutterSecureStorage();

  /// Gunakan konstruktor biasa (API resmi).
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  final _firebaseAuth = FirebaseAuth.instance;

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
      // set header agar request berikutnya otomatis authorized
      ApiClient.I.dio.options.headers['Authorization'] = 'Bearer $token';

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
      ApiClient.I.dio.options.headers['Authorization'] = 'Bearer $token';

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
      final res = await ApiClient.I.dio.get('/me');
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
      await ApiClient.I.dio.post('/email/verification-notification');
      return null;
    } on DioException catch (e) {
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
      return ok
          ? null
          : (data is Map && data['message'] != null)
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
      return ok
          ? null
          : (data is Map && data['message'] != null)
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
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// LOGOUT (revoke Google + sign out Firebase + bersihkan token lokal)
  Future<void> logout() async {
    try {
      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
      await _storage.delete(key: 'user_token');
      await _storage.delete(key: 'user_data');
      ApiClient.I.dio.options.headers.remove('Authorization');
    } catch (_) {
      // ignore
    }
  }

  /// LOGIN WITH GOOGLE → Firebase → tukar idToken dengan token backend
  Future<AuthResult> loginWithGoogle() async {
    try {
      _logger.i('1) Mulai login Google');

      // 2) Coba silent sign-in terlebih dahulu, jika gagal baru interaktif
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        _logger.i('2) Silent sign-in berhasil: ${googleUser.email}');
      } else {
        _logger.i('2) Silent sign-in gagal, membuka Google Sign-In interaktif');
        googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _logger.w('User membatalkan Google Sign-In');
          return const AuthResult(
            status: false,
            message: 'Login dengan Google dibatalkan',
          );
        }
        _logger.i('2) Google user: ${googleUser.email}');
      }

      // 3) Ambil token Google
      final googleAuth = await googleUser.authentication;

      // 4) Buat credential & login ke Firebase
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final userCred = await _firebaseAuth.signInWithCredential(credential);
      final fbUser = userCred.user;
      if (fbUser == null) {
        return const AuthResult(
          status: false,
          message: 'Gagal mendapatkan data pengguna dari Google',
        );
      }

      // 5) Ambil Firebase ID token
      final idToken = await fbUser.getIdToken();
      if (idToken == null) {
        await logout();
        return const AuthResult(
          status: false,
          message: 'Gagal mendapatkan token dari Firebase',
        );
      }

      // 6) Verifikasi ke backend → terima token & user
      final backendData = await verifyWithBackend(idToken);
      final token = backendData['token']?.toString();
      if (token == null || token.isEmpty) {
        await logout();
        return const AuthResult(
          status: false,
          message: 'Token tidak valid dari backend',
        );
      }

      await _storage.write(key: 'user_token', value: token);
      ApiClient.I.dio.options.headers['Authorization'] = 'Bearer $token';

      final userJson = (backendData['user'] ?? {}) as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      return AuthResult(
        status: true,
        message:
            backendData['message']?.toString() ??
            'Login dengan Google berhasil.',
        token: token,
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      _logger.e('FirebaseAuthException: ${e.code} - ${e.message}');
      return AuthResult(
        status: false,
        message: 'Firebase Auth Error: ${e.message}',
      );
    } on DioException catch (e) {
      _logger.e('DioException: ${e.message} | ${e.response?.data}');
      return AuthResult(
        status: false,
        message: _extractApiError(e, 'Gagal login dengan Google.'),
      );
    } catch (e, st) {
      _logger.e('Unexpected error: $e', stackTrace: st);
      return AuthResult(status: false, message: 'Terjadi kesalahan: $e');
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

  /// Verifikasi token Firebase dengan backend Laravel
  Future<Map<String, dynamic>> verifyWithBackend(String idToken) async {
    final response = await ApiClient.I.dio.post(
      '/firebase-login',
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'Accept': 'application/json',
        },
      ),
    );
    return response.data as Map<String, dynamic>;
  }
}
