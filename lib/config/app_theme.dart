import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundLight,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      titleMedium: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      bodyLarge: TextStyle(
        color: Colors.black87,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Colors.black54,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: Colors.black45,
        fontSize: 12,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      surface: AppColors.surface,
      background: AppColors.backgroundDark, // Keeping for backward compatibility
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundDarker.withOpacity(0.9),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    ),
  );

  // Custom decoration for gradient background
  static BoxDecoration get backgroundDecoration => const BoxDecoration(
        gradient: AppColors.darkGradient,
      );
}
