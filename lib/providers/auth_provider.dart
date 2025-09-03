import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _loading = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get loading => _loading;

  Future<void> init() async {
    // Restore token dari secure storage, lalu coba /me
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
    } catch (_) {
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

      // simpan token supaya auto-login
      await const FlutterSecureStorage().write(
        key: 'user_token',
        value: _token,
      );

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
    final res = await AuthService.I.register(name, email, password);
    _loading = false;

    if (res.status) {
      _user = res.user;
      _token = res.token;
      await const FlutterSecureStorage().write(
        key: 'user_token',
        value: _token,
      );
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
    await AuthService.I.logout();
    await const FlutterSecureStorage().delete(key: 'user_token');
    _user = null;
    _token = null;
    _loading = false;

    // pastikan juga sign-out Google/Firebase (biar bersih)
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    notifyListeners();
  }

  /// === GOOGLE LOGIN BARU ===
  /// 1) Sign-in Google → dapat Google tokens
  /// 2) Buat Firebase credential → sign-in Firebase (agar dapat idToken)
  /// 3) Kirim idToken ke backend → tukar dengan token aplikasi + user
  Future<String?> loginWithGoogle() async {
    _loading = true;
    notifyListeners();

    try {
      final result = await AuthService.I.loginWithGoogle();

      if (result.status && result.token != null && result.user != null) {
        _token = result.token;
        _user = result.user;

        await const FlutterSecureStorage().write(
          key: 'user_token',
          value: _token,
        );

        notifyListeners();
        return null; // success
      } else {
        await AuthService.I.logout();
        _token = null;
        _user = null;
        return result.message ?? 'Login gagal';
      }
    } catch (e) {
      await AuthService.I.logout();
      _token = null;
      _user = null;
      return 'Terjadi kesalahan: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
