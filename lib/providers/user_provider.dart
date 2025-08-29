import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> init() async {
    await loadUser(cacheFirst: true);
  }

  Future<void> loadUser({bool cacheFirst = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (cacheFirst) {
        final cached = await UserService.getProfile(forceRefresh: false);
        if (cached != null) {
          _user = cached;
          _error = null;
          notifyListeners();
        }

        final fresh = await UserService.getProfile(forceRefresh: true);
        if (fresh != null) {
          if (_user == null || fresh.updatedAt != _user!.updatedAt) {
            _user = fresh;
            _error = null;
            notifyListeners();
          }
        }
      } else {
        final fresh = await UserService.getProfile(forceRefresh: true);
        if (fresh != null) {
          _user = fresh;
          _error = null;
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadUser(cacheFirst: false);

  void updateUser(UserModel newUser) {
    if (_user == null ||
        newUser.updatedAt != _user!.updatedAt ||
        newUser.name != _user!.name ||
        newUser.email != _user!.email ||
        newUser.avatar != _user!.avatar) {
      _user = newUser;
      notifyListeners();
    }
  }

  Future<void> clear() async {
    _user = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
