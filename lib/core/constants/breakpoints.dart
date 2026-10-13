import 'package:flutter/widgets.dart';

/// Puntos de quiebre centralizados para el diseño adaptable.
class Breakpoints {
  Breakpoints._();

  /// Por debajo de este ancho se considera móvil.
  static const double tablet = 600;

  /// Desde este ancho se considera escritorio.
  static const double desktop = 1024;

  /// Anchos máximos de contenido.
  static const double formMaxWidth = 440;
  static const double dialogMaxWidth = 520;
  static const double contentMaxWidth = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}

enum ScreenSize { mobile, tablet, desktop }

ScreenSize screenSizeForWidth(double width) {
  if (width >= Breakpoints.desktop) return ScreenSize.desktop;
  if (width >= Breakpoints.tablet) return ScreenSize.tablet;
  return ScreenSize.mobile;
}
