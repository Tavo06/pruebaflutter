import 'package:flutter/material.dart';

/// Paleta de marca. Cambia estos valores para adaptar la identidad visual.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3478F6);
  static const Color violet = Color(0xFF6547F5);
  static const Color navy = Color(0xFF14264F);
  static const Color background = Color(0xFFF5F7FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF172344);
  static const Color textSecondary = Color(0xFF6F7B98);
  static const Color success = Color(0xFF16A875);
  static const Color error = Color(0xFFDC4658);
  static const Color warning = Color(0xFFE9A23B);

  // Variantes para el tema oscuro.
  static const Color darkBackground = Color(0xFF0D1730);
  static const Color darkSurface = Color(0xFF16223F);
  static const Color darkSurfaceHigh = Color(0xFF1E2B4D);
  static const Color darkTextPrimary = Color(0xFFE8ECF8);
  static const Color darkTextSecondary = Color(0xFF9BA6C2);

  /// Degradado discreto para botones principales y banners.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
