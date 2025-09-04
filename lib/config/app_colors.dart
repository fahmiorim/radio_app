import 'package:flutter/material.dart';

class AppColors {
  // Base Colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color accent = Color(0xFF191414);
  static const Color backgroundDark = Color(0xFF0A1F3A); // Biru tua
  static const Color backgroundDarker = Color(0xFF051A32); // Biru lebih tua
  static const Color backgroundLight = Color(0xFFE6F0FF); // Biru muda untuk tema terang
  static const Color surface = Color(0xFF1A2E4A); // Biru tua untuk surface
  static const Color surfaceLight = Color(0xFF2A3D59); // Biru tua lebih terang
  static const Color cardBackground = Color(0xFF1E2D47); // Warna untuk card background
  
  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3);

  // Semantic Colors
  static const Color error = Color(0xFFB00020);
  
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
}
