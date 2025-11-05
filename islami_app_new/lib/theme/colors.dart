import 'package:flutter/material.dart';

/// İslami App için renk paleti
/// Material 3 teması ile uyumlu, İslami kimliğe uygun renkler
class AppColors {
  // Primary Colors - Beyaz tema için yeşil tonları
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  
  // Secondary Colors - Beyaz tema için altın tonları
  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFE65100);
  
  // Neutral Colors - Beyaz tema
  static const Color surface = Colors.white;
  static const Color background = Colors.white;
  static const Color onSurface = Color(0xFF212121);
  static const Color onBackground = Color(0xFF212121);
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2196F3);
  
  // Islamic Theme Specific Colors
  static const Color islamicGreen = Color(0xFF00695C);
  static const Color islamicGold = Color(0xFFFFAB00);
  static const Color prayerTime = Color(0xFFE8F5E8);
  static const Color prayerTimeText = Color(0xFF2E7D32);
  
  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF00695C),
    Color(0xFF4DB6AC),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFFFFAB00),
    Color(0xFFFFD54F),
  ];
  
  static const List<Color> prayerTimeGradient = [
    Color(0xFFE8F5E8),
    Color(0xFFF1F8E9),
  ];
  
  // Dark Theme Colors
  static const Color darkSurface = Color(0xFF212121);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkOnSurface = Colors.white;
  static const Color darkOnBackground = Colors.white;
  
  // Card Colors
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF2C2C2C);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF424242);
  static const Color outline = Color(0xFFE0E0E0);
  
  // Dark mode text colors
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextHint = Color(0xFF757575);
  
  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x3A000000);
}