import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
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
    // Dipanggil saat app start (restore login)
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
      // Cek validitas token dengan memanggil endpoint /me
      final me = await AuthService.I.getCurrentUser();
      if (me != null) {
        _user = me;
        _token = token; // Simpan token asli
      } else {
        // Token tidak valid, hapus dari penyimpanan
        await storage.delete(key: 'user_token');
        _token = null;
        _user = null;
      }
    } catch (e) {
      // Jika terjadi error, hapus token yang tidak valid
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
      return null; // null = tidak ada error
    } else {
      notifyListeners();
      return res.message; // pesan error
    }
  }

  Future<void> loginWithFirebase(fb.User user) async {
    _loading = true;
    notifyListeners();

    final token = await user.getIdToken();
    await const FlutterSecureStorage().write(key: 'user_token', value: token);

    _user = UserModel(
      id: 0,
      name: user.displayName ?? 'Tidak ada nama',
      email: user.email ?? 'Tidak ada email',
      phone: user.phoneNumber,
      address: null,
      avatar: user.photoURL,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _token = token;

    _loading = false;
    notifyListeners();
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
