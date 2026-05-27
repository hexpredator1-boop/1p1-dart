import 'package:flutter/material.dart';

class AppColors {
  static const bg      = Color(0xFF0A0A0A);
  static const surface = Color(0xFF111111);
  static const border  = Color(0xFF222222);
  static const text    = Color(0xFFF0F0F0);
  static const dim     = Color(0xFF444444);
  static const accent  = Color(0xFFE8FF47);
  static const accentDim = Color(0xFFB8CC38);
  static const wrong   = Color(0xFF7A2020);
  static const sheet   = Color(0xFF161616);
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bg,
        primary: AppColors.accent,
        onPrimary: AppColors.bg,
        onSurface: AppColors.text,
      ),
      fontFamily: 'monospace',
      useMaterial3: true,
    );
  }
}
