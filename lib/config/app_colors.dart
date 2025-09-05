import 'package:flutter/material.dart';

// ========== Component Color Classes ==========
class _PlayerColors {
  final Color background = const Color(0xFF121212);
  final Color controls = const Color(0xFFFFFFFF);
  final Color progressBackground = const Color(0x4DFFFFFF);
  final Color progressPlayed = const Color(0xFF1E88E5);
  final Color progressBuffered = const Color(0x66FFFFFF);
  final Color liveIndicator = const Color(0xFFFE2C55);
  final Color liveBadge = const Color(0xFFFF0000);
}

class _ButtonColors {
  final Color primary = const Color(0xFF1E88E5);
  final Color primaryText = const Color(0xFFFFFFFF);
  final Color secondary = const Color(0x1FFFFFFF);
  final Color secondaryText = const Color(0xFFFFFFFF);
}

class _InputColors {
  static const Color background = Color(0x1AFFFFFF);
  static const Color border = Color(0x33FFFFFF);
  static const Color text = Color(0xFFFFFFFF);
  static const Color hint = Color(0xB3FFFFFF);
}

class _ChatColors {
  static const Color background = Color(0xFF000000);
  static const Color inputBackground = Color(0xFF1E1E1E);
  static const Color hintText = Color(0xFF9E9E9E);
}

class _TabColors {
  static const Color selected = Color(0xFFFFFFFF);
  static const Color unselected = Color(0xB3FFFFFF);
  static const Color indicator = Color(0xFFFFFFFF);
}

class _LoadingColors {
  static const Color shimmerBase = Color(0x1AFFFFFF);
  static const Color shimmerHighlight = Color(0x33FFFFFF);
}

class _SocialMediaColors {
  static const Color facebook = Color(0xFF1877F2);
  static const Color twitter = Color(0xFF1DA1F2);
  static const Color instagram = Color(0xFFE1306C);
  static const Color youtube = Color(0xFFFF0000);
  static const Color whatsapp = Color(0xFF25D366);
}

class _SystemUIColors {
  static const Color statusBar = Color(0x00000000);
  static const Color systemNavigationBar = Color(0xFF121212);
}

/// A collection of all color constants used throughout the app.
/// Organized by theme and component for better maintainability.
class AppColors {
  // ========== Light Theme ==========
  static const Color lightPrimary = Color(
    0xFF0D47A1,
  ); // Biru tua yang lebih tegas
  static const Color lightBackground = Color(
    0xFF0D47A1,
  ); // Biru muda yang lebih tegas
  static const Color lightSurface = Color(
    0xFF0D47A1,
  ); // Biru sangat muda untuk surface

  // Light Text Colors
  static const Color lightTextPrimary = Color(0xFF0D47A1);
  static const Color lightTextSecondary = Color(0xFF0D47A1);
  static const Color lightTextTertiary = Color(0xFF1A73E8);
  static const Color lightTextHint = Color(0xFF5E97F6);

  // Light UI Colors
  static const Color lightCardSurface = Color(0xFFE8F4FF);
  static const Color lightDivider = Color(0x66000000);
  static const Color lightBorder = Color(0xFF90CBF9);
  static const Color lightSentBubble = lightPrimary;
  static const Color lightSentBubbleText = Color(0xFFFFFFFF);
  static const Color lightReceivedBubble = Color(0xFFEEEEEE);
  static const Color lightReceivedBubbleText = Color(0xDD000000);

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
  static const Color darkTextHint = Color(0xFF9E9E9E);

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
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  static const Color disabled = Color(0xFF9E9E9E);

  // ========== Component Colors ==========
  static final player = _PlayerColors();
  static final button = _ButtonColors();
  static final input = _InputColors();
  static final chat = _ChatColors();
  static final tab = _TabColors();
  static final loading = _LoadingColors();
  static final social = _SocialMediaColors();
  static final systemUI = _SystemUIColors();

  // ========== Common Color Aliases ==========
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color red = Colors.red;
  static const Color green = Colors.green;
  static const Color blue = Colors.blue;
  static const Color yellow = Colors.yellow;
  static const Color orange = Colors.orange;
  static const Color purple = Colors.purple;
  static const Color pink = Colors.pink;
  static const Color teal = Colors.teal;
  static const Color cyan = Colors.cyan;
  static const Color brown = Colors.brown;
  static const Color grey = Colors.grey;
  static const Color blueGrey = Colors.blueGrey;

  // ========== Live/Streaming Colors ==========
  Color get liveIndicator => player.liveIndicator;
  Color get liveBadge => player.liveBadge;

  // ========== Chat Colors ==========
  static const Color chatBackground = _ChatColors.background;
  static const Color chatInputBackground = _ChatColors.inputBackground;
  static const Color chatHintText = _ChatColors.hintText;

  // ========== Deprecated (Kept for backward compatibility) ==========
  @Deprecated('Use AppColors.lightPrimary instead')
  static const Color primary = lightPrimary;

  @Deprecated('Use AppColors.lightBackground instead')
  static const Color backgroundDark = lightBackground;

  @Deprecated('Use AppColors.lightTextPrimary instead')
  static const Color textPrimary = lightTextPrimary;

  @Deprecated('Use AppColors.lightTextSecondary instead')
  static const Color textSecondary = lightTextSecondary;

  @Deprecated('Use AppColors.lightTextTertiary instead')
  static const Color textTertiary = lightTextTertiary;

  @Deprecated('Use AppColors.lightTextHint instead')
  static const Color textHint = lightTextHint;

  @Deprecated('Use AppColors.lightCardSurface instead')
  static const Color cardSurface = lightCardSurface;

  @Deprecated('Use AppColors.lightDivider instead')
  static const Color dividerColor = lightDivider;

  @Deprecated('Use AppColors.lightBorder instead')
  static const Color borderColor = lightBorder;
}
