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

  /// Always fetches fresh data from the server
  Future<void> fetchUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Always force refresh to get latest data from server
      _user = await UserService.getProfile(forceRefresh: true);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow; // Re-throw to allow error handling in the UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the user data with new values
  void updateUser(UserModel newUser) {
    _user = newUser;
    notifyListeners();
  }
}
