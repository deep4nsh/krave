// lib/src/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Slate Base
  static const Color background = Color(0xFF0F172A); // Deep Slate Navy
  static const Color surface = Color(0xFF1E293B);    // Slate Surface
  static const Color card = Color(0xFF1E293B);
  
  // Emerald Accent
  static const Color primary = Color(0xFF10B981);   // Elegant Emerald
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF34D399);

  // Secondary/Support
  static const Color secondary = Color(0xFF64748B); // Slate Grey
  static const Color accent = Color(0xFFFACC15);    // Amber/Gold for contrast
  
  // Text
  static const Color textHigh = Color(0xFFF8FAFC);
  static const Color textMed = Color(0xFFCBD5E1);
  static const Color textLow = Color(0xFF94A3B8);

  // Glassmorphism helpers
  static const Color glassWhite = Color(0x0DFFFFFF);  // White with 0.05 alpha
  static const Color glassBorder = Color(0x1AFFFFFF); // White with 0.1 alpha
}
