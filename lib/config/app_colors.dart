import 'package:flutter/material.dart';

class AppColors {
  // Base Colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color accent = Color(0xFF191414);
  static const Color backgroundDark = Color(0xFF121212);
  
  // Bubble decorations
  static const double bubbleDefaultOpacity = 0.05; // Biru tua
  static const Color backgroundDarker = Color(0xFF051A32); // Biru lebih tua
  static const Color backgroundLight = Color(0xFFE6F0FF); // Biru muda untuk tema terang
  static const Color surface = Color(0xFF1A2E4A); // Biru tua untuk surface
  static const Color surfaceLight = Color(0xFF2A3D59); // Biru tua lebih terang
  static const Color cardBackground = Color(0xFF1E2D47); // Warna untuk card background
  
  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF000000);
  static const Color textHint = Color(0xFF9E9E9E);

  // UI Elements
  static const Color divider = Color(0x1FFFFFFF);
  static const Color disabled = Color(0xFF9E9E9E);
  static const Color border = Color(0xFF2A2A2A);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  
  // Background Overlays
  static const Color overlayLight = Color(0x0DFFFFFF); // 5% white
  static const Color overlayMedium = Color(0x1FFFFFFF); // 12% white
  static const Color overlayDark = Color(0x61FFFFFF); // 38% white
  
  // Gradients
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A1A),
      Color(0xFF121212),
      Color(0xFF0A0A0A),
    ],
  );
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E88E5),
      Color(0xFF1565C0),
    ],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1E1E),
      Color(0xFF2A2A2A),
    ],
  );

  // Article specific
  static const Color articleBackground = Color(0xFF0A1F3A);
  static const Color articleContentBackground = Color(0x1AFFFFFF);
  
  // Player specific
  static const Color playerBackground = Color(0xFF121212);
  static const Color playerControls = Color(0xFFFFFFFF);
  static const Color playerProgressBackground = Color(0x4DFFFFFF);
  static const Color playerProgressPlayed = Color(0xFF1E88E5);
  static const Color playerProgressBuffered = Color(0x66FFFFFF);
  
  // Buttons
  static const Color buttonPrimary = Color(0xFF1E88E5);
  static const Color buttonPrimaryText = Color(0xFFFFFFFF);
  static const Color buttonSecondary = Color(0x1FFFFFFF);
  static const Color buttonSecondaryText = Color(0xFFFFFFFF);
  
  // Icons
  static const Color iconPrimary = Color(0xFFFFFFFF);
  static const Color iconSecondary = Color(0xFFB3B3B3);
  static const Color iconActive = Color(0xFF1E88E5);
  
  // Cards
  static const Color cardSurface = Color(0xFF1E2D47);
  static const Color cardElevated = Color(0xFF2A3D59);
  
  // Input Fields
  static const Color inputBackground = Color(0x1AFFFFFF);
  static const Color inputBorder = Color(0x33FFFFFF);
  static const Color inputText = Color(0xFFFFFFFF);
  static const Color inputHint = Color(0xB3FFFFFF);
  
  // Tabs
  static const Color tabSelected = Color(0xFFFFFFFF);
  static const Color tabUnselected = Color(0xB3FFFFFF);
  static const Color tabIndicator = Color(0xFFFFFFFF);
  
  // Status Bar
  static const Color statusBar = Color(0x00000000);
  static const Color systemNavigationBar = Color(0xFF121212);
  
  // Loading
  static const Color shimmerBase = Color(0x1AFFFFFF);
  static const Color shimmerHighlight = Color(0x33FFFFFF);
  
  // Social Media
  static const Color facebook = Color(0xFF1877F2);
  static const Color twitter = Color(0xFF1DA1F2);
  static const Color instagram = Color(0xFFE1306C);
  static const Color youtube = Color(0xFFFF0000);
  static const Color whatsapp = Color(0xFF25D366);
  
  // Additional
  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;
  static const Color white = Colors.white;
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
}
