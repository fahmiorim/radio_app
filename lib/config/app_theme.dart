import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Common text styles
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: AppColors.textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: AppColors.textTertiary,
    ),
  );

  // Common app bar theme
  static const AppBarTheme _appBarTheme = AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: AppColors.backgroundDark,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    iconTheme: IconThemeData(
      color: AppColors.iconPrimary,
      size: 24,
    ),
  );

  // Common card theme data
  static final CardThemeData _cardThemeData = CardThemeData(
    color: AppColors.cardSurface,
    elevation: 2,
    margin: const EdgeInsets.all(8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Common button theme
  static final ButtonThemeData _buttonTheme = ButtonThemeData(
    buttonColor: AppColors.buttonPrimary,
    disabledColor: AppColors.disabled,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  /// Creates a decorative bubble widget that can be positioned in a Stack
  /// 
  /// Parameters:
  /// - `context`: BuildContext untuk mengakses theme
  /// - `size`: Ukuran bubble (lebar dan tinggi)
  /// - `top`: Posisi dari atas (opsional)
  /// - `bottom`: Posisi dari bawah (opsional)
  /// - `left`: Posisi dari kiri (opsional)
  /// - `right`: Posisi dari kanan (opsional)
  /// - `opacity`: Opasitas bubble (default: 0.05)
  /// - `usePrimaryColor`: Jika true, gunakan warna primary theme, 
  ///    jika false gunakan warna onSurface theme
  /// 
  /// Example usage:
  /// ```dart
  /// Stack(
  ///   children: [
  ///     AppTheme.bubble(
  ///       context,
  ///       size: 200,
  ///       top: -50,
  ///       right: -50,
  ///     ),
  ///     // Other widgets
  ///   ],
  /// )
  /// ```
  static Widget bubble(
    BuildContext context, {
    Key? key,
    double size = 200,
    double? top,
    double? bottom,
    double? left,
    double? right,
    double opacity = AppColors.bubbleDefaultOpacity,
    bool usePrimaryColor = false,
  }) {
    return Positioned(
      key: key,
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (usePrimaryColor 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.onSurface
          ).withOpacity(opacity),
        ),
      ),
    );
  }

  // Common input decoration theme
  static final InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.inputBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    hintStyle: const TextStyle(color: AppColors.textHint),
    errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
  );

  // Common tab bar theme data
  static const TabBarThemeData _tabBarThemeData = TabBarThemeData(
    labelColor: AppColors.tabSelected,
    unselectedLabelColor: AppColors.tabUnselected,
    indicatorColor: AppColors.tabIndicator,
    labelStyle: TextStyle(fontWeight: FontWeight.bold),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
  );

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.accent,
        secondaryContainer: AppColors.accent,
        surface: AppColors.surfaceLight,
        background: AppColors.backgroundLight,
        error: AppColors.error,
        onPrimary: AppColors.textLight,
        onSecondary: AppColors.textLight,
        onSurface: AppColors.textDark,
        onBackground: AppColors.textDark,
        onError: AppColors.textLight,
      ),
      appBarTheme: _appBarTheme.copyWith(
        backgroundColor: AppColors.backgroundLight,
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      cardTheme: _cardThemeData.copyWith(
        color: AppColors.white,
        surfaceTintColor: AppColors.white,
      ),
      textTheme: _textTheme.copyWith(
        displayLarge: _textTheme.displayLarge?.copyWith(color: AppColors.textDark),
        displayMedium: _textTheme.displayMedium?.copyWith(color: AppColors.textDark),
        displaySmall: _textTheme.displaySmall?.copyWith(color: AppColors.textDark),
        headlineMedium: _textTheme.headlineMedium?.copyWith(color: AppColors.textDark),
        headlineSmall: _textTheme.headlineSmall?.copyWith(color: AppColors.textDark),
        titleLarge: _textTheme.titleLarge?.copyWith(color: AppColors.textDark),
        bodyLarge: _textTheme.bodyLarge?.copyWith(color: AppColors.textDark),
      ),
      buttonTheme: _buttonTheme,
      inputDecorationTheme: _inputDecorationTheme.copyWith(
        fillColor: AppColors.white,
        labelStyle: const TextStyle(color: AppColors.textDark),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.iconPrimary,
        size: 24,
      ),
      tabBarTheme: _tabBarThemeData,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.accent,
        secondaryContainer: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.backgroundDark,
        error: AppColors.error,
        onPrimary: AppColors.textLight,
        onSecondary: AppColors.textLight,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: AppColors.textLight,
      ),
      appBarTheme: _appBarTheme,
      cardTheme: _cardThemeData,
      textTheme: _textTheme,
      buttonTheme: _buttonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundDarker.withOpacity(0.9),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.iconPrimary,
        size: 24,
      ),
      tabBarTheme: _tabBarThemeData,
    );
  }

  // Common theme data
  static ThemeData getThemeData({required bool isDark}) {
    return isDark ? darkTheme : lightTheme;
  }

  // Custom decoration for gradient background
  static BoxDecoration get backgroundDecoration => const BoxDecoration(
        gradient: AppColors.darkGradient,
      );
}
