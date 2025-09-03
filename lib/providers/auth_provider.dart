import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../config/api_client.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _loading = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get loading => _loading;

  Future<void> init() async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'user_token');

    if (token == null || token.isEmpty) {
      _token = null;
      _user = null;
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final me = await AuthService.I.getCurrentUser();
      if (me != null) {
        _user = me;
        _token = token;
      } else {
        await storage.delete(key: 'user_token');
        _token = null;
        _user = null;
      }
    } catch (e) {
      await storage.delete(key: 'user_token');
      _token = null;
      _user = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    final res = await AuthService.I.login(email, password);
    _loading = false;

    if (res.status) {
      _user = res.user;
      _token = res.token;
      notifyListeners();
      return null;
    } else {
      notifyListeners();
      return res.message;
    }
  }

  Future<void> loginWithFirebase(fb.User user) async {
    _loading = true;
    notifyListeners();

    try {
      final idToken = await user.getIdToken(true);

      final res = await ApiClient.I.dio.post(
        '/firebase-login',
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Accept': 'application/json',
          },
        ),
        data: {
          'name': user.displayName,
          'email': user.email,
          'photo_url': user.photoURL,
        },
      );

      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map;

        if (data['status'] == true) {
          final jwtToken = data['token'] as String;

          await const FlutterSecureStorage().write(
            key: 'user_token',
            value: jwtToken,
          );

          final userData = Map<String, dynamic>.from(data['data'] as Map);

          _user = UserModel(
            id: userData['id'] as int,
            name: (userData['name'] ?? '') as String,
            email: (userData['email'] ?? '') as String,
            phone: userData['phone'] as String?,
            address: userData['address'] as String?,
            avatar: userData['avatar'] as String?,
            isActive: true,
            createdAt: DateTime.parse(userData['created_at'] as String),
            updatedAt: DateTime.now(),
          );

          _token = jwtToken;

          await const FlutterSecureStorage().write(
            key: 'user_data',
            value: jsonEncode(userData),
          );
        } else {
          throw Exception('Login gagal: ${data['message'] ?? 'Unknown'}');
        }
      } else {
        throw Exception('HTTP ${res.statusCode}: ${res.statusMessage}');
      }
    } on DioException catch (e) {
      print('Dio type: ${e.type} | msg: ${e.message}');
      print('HTTP: ${e.response?.statusCode} | body: ${e.response?.data}');
      rethrow;
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> register(String name, String email, String password) async {
    _loading = true;
    notifyListeners();
    final res = await AuthService.I.register(name, email, password);
    _loading = false;

    if (res.status) {
      _user = res.user;
      _token = res.token;
      notifyListeners();
      return null;
    } else {
      notifyListeners();
      return res.message;
    }
  }

  Future<String?> resendVerificationEmail() async {
    _loading = true;
    notifyListeners();
    final res = await AuthService.I.resendVerificationEmail();
    _loading = false;
    notifyListeners();
    return res;
  }

  Future<bool> checkEmailVerified() async {
    _loading = true;
    notifyListeners();
    final res = await AuthService.I.checkEmailVerified();
    _loading = false;
    notifyListeners();
    return res;
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();

    try {
      // Panggil API logout jika diperlukan
      await ApiClient.I.dio.post('/logout');
    } catch (e) {
      // Tetap lanjutkan proses logout meskipun API gagal
    } finally {
      // Hapus token dan reset state
      await const FlutterSecureStorage().delete(key: 'user_token');
      _user = null;
      _token = null;
      _loading = false;
      notifyListeners();
    }
  }
}
