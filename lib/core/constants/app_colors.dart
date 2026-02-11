import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Color
  static const Color primary = Color(0xFFCCFF00); // Neon Green

  // Backgrounds
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF1E1E1E);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color textOnPrimary = Colors.black;

  // States
  static const Color error = Colors.redAccent;
  static const Color success = Color(0xFF00FF94); // Neon Green/Success
  static const Color warning = Color(0xFFFFAA00); // Neon Orange

  // Glassmorphism
  static final Color glassBackground = Colors.grey.shade900.withOpacity(0.7);
  static final Color glassBorder = Colors.white.withOpacity(0.1);
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFFD500F9);
}
