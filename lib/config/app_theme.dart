import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  // ---------- Light Theme ----------
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      background: AppColors.lightBackground,
      onBackground: AppColors.lightTextPrimary,
      error: AppColors.error,
      onError: AppColors.white,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightDivider,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.background,
      disabledColor: AppColors.disabled,
      colorScheme: colorScheme,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
        ),
        titleLarge: TextStyle(
          fontSize: 20, // Increased from 16 to 20
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
          height: 1.2, // Better line height for larger text
        ),
        bodyLarge: TextStyle(fontSize: 16, color: colorScheme.onBackground),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colorScheme.onBackground.withOpacity(0.7),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: colorScheme.onBackground.withOpacity(0.6),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.primary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimary,
        ),
        iconTheme: IconThemeData(color: colorScheme.onPrimary, size: 24),
        systemOverlayStyle:
            SystemUiOverlayStyle.light, // status bar icons putih
      ),
    );

    return base.copyWith(
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return colorScheme.onSurface.withOpacity(0.12);
            }
            return colorScheme.primary;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return colorScheme.onSurface.withOpacity(0.38);
            }
            return colorScheme.onPrimary;
          }),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          elevation: MaterialStateProperty.all(2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.9)),
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
        errorStyle: TextStyle(color: colorScheme.error, fontSize: 12),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.7),
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colorScheme.onBackground, size: 24),
    );
  }

  // ---------- Dark Theme ----------
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      disabledColor: AppColors.disabled,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        error: AppColors.error,
        onPrimary: AppColors.black,
        onSecondary: AppColors.black,
        onSurface: AppColors.darkTextPrimary,
        onBackground: AppColors.darkTextPrimary,
        onError: AppColors.black,
        brightness: Brightness.dark,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20, // Increased from 16 to 20
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
          height: 1.2, // Better line height for larger text
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.darkTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkTextSecondary),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.darkTextTertiary),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary, size: 24),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
    );

    return base.copyWith(
      cardTheme: CardThemeData(
        color: AppColors.darkCardSurface,
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MaterialStateColor.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return AppColors.grey700;
            }
            return AppColors.blueGrey800;
          }),
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.darkPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: TextStyle(color: AppColors.darkTextSecondary),
        hintStyle: TextStyle(color: AppColors.darkTextTertiary),
        errorStyle: TextStyle(color: AppColors.error, fontSize: 12),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextSecondary,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary, size: 24),
    );
  }

  // ---------- Helper ----------
  static ThemeData getThemeData(bool isDarkMode) {
    return isDarkMode ? darkTheme : lightTheme;
  }

  // Bubble dekoratif (opsional)
  static Widget bubble({
    required BuildContext context,
    required double size,
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool usePrimaryColor = true,
    double opacity = 0.1,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = usePrimaryColor
        ? colorScheme.primary.withOpacity(opacity)
        : (isDark
                ? colorScheme.surfaceVariant
                : colorScheme.secondary)
            .withOpacity(opacity);

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
