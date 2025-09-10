import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/services/auth_service.dart';
import 'package:radio_odan_app/config/api_client.dart';
import 'package:radio_odan_app/audio/audio_player_manager.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _loading = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => (_token ?? '').isNotEmpty;
  bool get loading => _loading;

  // ================= Init (restore session) =================
  Future<void> init() async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'user_token');

    if ((token ?? '').isEmpty) {
      _token = null;
      _user = null;
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      ApiClient.I.setBearer(token!);
      final me = await AuthService.I.getCurrentUser();
      if (me != null) {
        _user = me;
        _token = token;
      } else {
        await storage.delete(key: 'user_token');
        _token = null;
        _user = null;
        ApiClient.I.clearBearer();
      }
    } catch (_) {
      await storage.delete(key: 'user_token');
      _token = null;
      _user = null;
      ApiClient.I.clearBearer();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ================= Email/Password =================
  Future<String?> login(String email, String password) async {
    _loading = true;
    notifyListeners();

    final res = await AuthService.I.login(email, password);

    _loading = false;
    if (res.status) {
      _user = res.user;
      _token = res.token;
      if ((_token ?? '').isNotEmpty) ApiClient.I.setBearer(_token!);
      notifyListeners();
      return null;
    } else {
      notifyListeners();
      return res.message;
    }
  }

  Future<String?> register(String name, String email, String password) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await AuthService.I.register(name, email, password);

      if (res.status) {
        _user = res.user;
        _token = res.token;

        if ((_token ?? '').isNotEmpty) {
          ApiClient.I.setBearer(_token!);

          // Save token to secure storage
          final storage = const FlutterSecureStorage();
          await storage.write(key: 'user_token', value: _token);
        }

        return null; // Success, no error
      } else {
        // If failed, return error message
        return res.message.isNotEmpty
            ? res.message
            : 'Gagal melakukan registrasi';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ================= Firebase Login =================
  Future<String?> loginWithFirebase(fb.User user) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await AuthService.I.loginWithFirebaseUser(user);
      if (res.status) {
        _user = res.user;
        _token = res.token;

        if ((_token ?? '').isNotEmpty) ApiClient.I.setBearer(_token!);

        // optional persist extra
        await const FlutterSecureStorage().write(
          key: 'user_data',
          value: jsonEncode(res.user?.toJson() ?? {}),
        );

        return null; // sukses
      }
      return res.message;
    } on SocketException {
      return 'Koneksi jaringan bermasalah.';
    } catch (e) {
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ================= Misc =================
  Future<String?> resendVerificationEmail() async {
    _loading = true;
    notifyListeners();
    final res = await AuthService.I.resendVerificationEmail();
    _loading = false;
    notifyListeners();
    return res;
  }

  bool _isEmailVerified = false;
  bool get isEmailVerified => _isEmailVerified;

  Future<bool> checkEmailVerified() async {
    if (_isEmailVerified) return true;

    _loading = true;
    notifyListeners();

    try {
      _isEmailVerified = await AuthService.I.checkEmailVerified();
      return _isEmailVerified;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    try {
      await AuthService.I.logout();
    } finally {
      await AudioPlayerManager.instance.stop();
      await const FlutterSecureStorage().delete(key: 'user_token');
      _user = null;
      _token = null;
      ApiClient.I.clearBearer();
      _loading = false;
      notifyListeners();
    }
  }
}
