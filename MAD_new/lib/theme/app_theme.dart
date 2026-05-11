import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background colors
  static const Color background = Color(0xFF0D0F1A);
  static const Color cardBackground = Color(0xFF161A2C);
  static const Color cardBackgroundLight = Color(0xFF1C2039);
  static const Color surfaceLight = Color(0xFF232842);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E92A4);
  static const Color textMuted = Color(0xFF5A5E72);
  static const Color sectionLabel = Color(0xFF6B6F82);

  // Accent colors
  static const Color purple = Color(0xFF9B59E8);
  static const Color purpleLight = Color(0xFFB07FEB);
  static const Color pink = Color(0xFFE91E8C);
  static const Color pinkLight = Color(0xFFFF6EB4);
  static const Color orange = Color(0xFFFF8C42);
  static const Color orangeLight = Color(0xFFFFAA6B);
  static const Color green = Color(0xFF2ECC71);
  static const Color greenLight = Color(0xFF4ADE80);
  static const Color teal = Color(0xFF00C9A7);
  static const Color yellow = Color(0xFFFFD93D);
  static const Color yellowBg = Color(0xFF3D3520);
  static const Color red = Color(0xFFE74C3C);
  static const Color redLight = Color(0xFFFF6B6B);
  static const Color blue = Color(0xFF3498DB);
  static const Color blueLight = Color(0xFF5DADE2);
  static const Color cyan = Color(0xFF00BCD4);

  // Gradient colors
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFE91E8C), Color(0xFFFF6EB4)],
  );
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFB07FEB)],
  );
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF8C42), Color(0xFFFFAA6B)],
  );

  // Nav bar
  static const Color navBarBg = Color(0xFF0A0C15);
  static const Color navActive = Color(0xFF9B59E8);
  static const Color navInactive = Color(0xFF5A5E72);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.purple,
        surface: AppColors.cardBackground,
        onSurface: AppColors.textPrimary,
      ),
    );
  }
}
