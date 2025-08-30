import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  static const Duration _refreshCooldown = Duration(seconds: 30);

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;
  Completer<void>? _currentLoadCompleter;
  Timer? _debounceTimer;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get hasData => _user != null;

  Future<void> init() async {
    await loadUser(cacheFirst: true);
  }

  Future<void> loadUser({bool cacheFirst = true}) async {
    // If a load is already in progress, return its future
    if (_currentLoadCompleter != null) {
      return _currentLoadCompleter!.future;
    }

    // Check cooldown period
    if (!cacheFirst &&
        _lastUpdated != null &&
        DateTime.now().difference(_lastUpdated!) < _refreshCooldown) {
      return;
    }

    _currentLoadCompleter = Completer<void>();
    _isLoading = true;
    _error = null;

    // Only notify if we already have data to prevent unnecessary rebuilds
    if (_user != null) notifyListeners();

    try {
      if (cacheFirst) {
        // Try to get cached data first
        try {
          final cached = await UserService.getProfile(forceRefresh: false);
          if (cached != null) {
            _user = cached;
            _error = null;
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Error loading cached user data: $e');
        }
      }

      // Always try to get fresh data
      try {
        final fresh = await UserService.getProfile(forceRefresh: true);
        if (fresh != null) {
          if (_user == null || !_isUserEqual(_user!, fresh)) {
            _user = fresh;
            _error = null;
            _lastUpdated = DateTime.now();
            notifyListeners();
          }
        }
      } catch (e) {
        // Only throw error if we don't have any cached data
        if (_user == null) {
          _error = e.toString();
          rethrow;
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      _currentLoadCompleter?.complete();
      _currentLoadCompleter = null;
    }
  }

  bool _isUserEqual(UserModel a, UserModel b) {
    return a.id == b.id &&
        a.name == b.name &&
        a.email == b.email &&
        a.avatar == b.avatar &&
        a.updatedAt == b.updatedAt;
  }

  Future<void> refresh() {
    // Cancel any pending debounce
    _debounceTimer?.cancel();

    // If already refreshing, return the current future
    if (_isLoading) {
      return _currentLoadCompleter?.future ?? Future.value();
    }

    // Debounce refresh to prevent multiple rapid calls
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    final completer = Completer<void>();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        await loadUser(cacheFirst: false);
        completer.complete();
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  void updateUser(UserModel newUser) {
    if (_user == null || !_isUserEqual(_user!, newUser)) {
      _user = newUser;
      _lastUpdated = DateTime.now();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> clear() async {
    _user = null;
    _error = null;
    _isLoading = false;
    _lastUpdated = null;
    notifyListeners();
  }
}
