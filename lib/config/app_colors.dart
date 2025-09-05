import 'package:flutter/material.dart';

// ========== Component Color Classes ==========
class _PlayerColors {
  final Color controls = const Color(0xFFFFFFFF);
}

class _ButtonColors {
  final Color primaryText = const Color(0xFFFFFFFF);
}

class _ChatColors {
  static const Color background = Color(0xFF000000);
  static const Color inputBackground = Color(0xFF1E1E1E);
  static const Color hintText = Color(0xFF9E9E9E);
}


class AppColors {
  // ========== Light Theme ==========
  static const Color lightPrimary = Color(0xFF1976D2); // Medium blue
  static const Color lightBackground = Color(0xFF0D47A1); // Darker blue
  static const Color lightSurface = Color(
    0xFF0D1B2A,
  ); // Very dark blue (almost black)

  // Light Text Colors
  static const Color lightTextPrimary = Color.fromARGB(
    255,
    35,
    35,
    35,
  ); // White for better contrast
  static const Color lightTextSecondary = Color(0xFFBBDEFB); // Light blue
  static const Color lightTextTertiary = Color(0xFF90CAF9); // Lighter blue

  // Light UI Colors
  static const Color lightCardSurface = Color(
    0x1AFFFFFF,
  ); // Semi-transparent white
  static const Color lightDivider = Color(0x33FFFFFF); // Semi-transparent white
  static const Color lightBorder = Color(
    0x33FFFFFF,
  ); // Semi-transparent white border
  static const Color lightSentBubble = Color(0xFF1976D2); // Medium blue
  static const Color lightSentBubbleText = Color(0xFFFFFFFF); // White text
  static const Color lightReceivedBubble = Color(0xFF1E1E1E); // Dark gray
  static const Color lightReceivedBubbleText = Color(0xFFFFFFFF); // White text

  // ========== Dark Theme ==========
  static const Color darkPrimary = Color(
    0xFF90CAF9,
  ); // Lighter blue for better visibility on dark backgrounds
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);

  // Dark Text Colors
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0BEC5);
  static const Color darkTextTertiary = Color(0xFF757575);

  // Dark UI Colors
  static const Color darkCardSurface = Color(0xFF1E1E1E);
  static const Color darkDivider = Color(0x1FFFFFFF);
  static const Color darkBorder = Color(0xFF424242);
  static const Color darkSentBubble = darkPrimary;
  static const Color darkSentBubbleText = darkTextPrimary;
  static const Color darkReceivedBubble = darkSurface;
  static const Color darkReceivedBubbleText = Color(0xFFFFFFFF);

  // ========== Common Colors ==========
  static const Color accent = Color(0xFF34A853);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color disabled = Color(0xFF9E9E9E);

  // ========== Component Colors ==========
  static final player = _PlayerColors();
  static final button = _ButtonColors();

  // ========== Common Color Aliases ==========
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color red = Colors.red;
  static const Color green = Colors.green;
  static const Color orange = Colors.orange;
  static const Color grey = Colors.grey;
  static const Color blueGrey = Colors.blueGrey;
  static const Color redAccent = Colors.redAccent;
  static const Color amber300 = Color(0xFFFFD54F);
  static const Color orange700 = Color(0xFFF57C00);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey850 = Color(0xFF303030);
  static const Color white24 = Color(0x3DFFFFFF);

  // ========== Chat Colors ==========
  static const Color chatBackground = _ChatColors.background;
  static const Color chatInputBackground = _ChatColors.inputBackground;
  static const Color chatHintText = _ChatColors.hintText;

}
