import 'package:flutter/material.dart';

/// Paleta de marca: verde oliva como color dominante y terracota como acento.
///
/// Es el ÚNICO lugar con valores de color. Las pantallas usan
/// `Theme.of(context).colorScheme` y `context.palette` (ver `app_theme.dart`),
/// así cambian solas entre el tema claro y el oscuro.
class AppColors {
  AppColors._();

  // --- Tema claro -----------------------------------------------------------
  static const Color olive = Color(0xFF687447);
  static const Color oliveDark = Color(0xFF414B2C);
  static const Color oliveSoft = Color(0xFFE7EBD9);

  /// Acento puntual (detalles y acciones secundarias). No representa errores.
  static const Color terracotta = Color(0xFFC87955);

  static const Color background = Color(0xFFF7F8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceHigh = Color(0xFFF0F2EA);
  static const Color textPrimary = Color(0xFF25291F);
  static const Color textSecondary = Color(0xFF74786C);
  static const Color border = Color(0xFFE0E4D8);

  static const Color success = Color(0xFF2E7D55);
  static const Color error = Color(0xFFC64545);
  static const Color warning = Color(0xFFB7791F);

  // --- Tema oscuro ----------------------------------------------------------
  static const Color darkOlive = Color(0xFFA9B57F);
  static const Color darkOnOlive = Color(0xFF1F2412);
  static const Color darkOliveSoft = Color(0xFF353C25);
  static const Color darkTerracotta = Color(0xFFE09A7A);
  static const Color darkBackground = Color(0xFF151812);
  static const Color darkSurface = Color(0xFF1E221A);
  static const Color darkSurfaceHigh = Color(0xFF282D22);
  static const Color darkSidebar = Color(0xFF10130D);
  static const Color darkTextPrimary = Color(0xFFE8EBE0);
  static const Color darkTextSecondary = Color(0xFFA4A896);
  static const Color darkBorder = Color(0xFF343A2C);
  static const Color darkSuccess = Color(0xFF5DBB8A);
  static const Color darkError = Color(0xFFE57A7A);
  static const Color darkWarning = Color(0xFFDDA54A);

  // --- Marca de Google (solo para su logotipo, según sus directrices) ------
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleRed = Color(0xFFEA4335);
  static const Color googleYellow = Color(0xFFFBBC05);
  static const Color googleGreen = Color(0xFF34A853);
}
