import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  late ThemeMode _themeMode;
  final SharedPreferences? _prefs;

  ThemeProvider(this._prefs) {
    // Load saved theme mode or default to system
    final savedTheme = _prefs?.getString(_themeKey);
    _themeMode = _getThemeModeFromString(savedTheme) ?? ThemeMode.system;
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await _prefs?.setString(_themeKey, _themeMode.toString().split('.').last);
    notifyListeners();
  }

  static ThemeMode? _getThemeModeFromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }
}
