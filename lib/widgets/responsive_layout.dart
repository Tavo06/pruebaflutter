import 'package:flutter/material.dart';

import '../core/constants/breakpoints.dart';

/// Elige un diseño según el ancho disponible (no el de la pantalla), de modo
/// que también funciona dentro de paneles y ventanas redimensionadas.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (screenSizeForWidth(constraints.maxWidth)) {
          case ScreenSize.desktop:
            return (desktop ?? tablet ?? mobile)(context);
          case ScreenSize.tablet:
            return (tablet ?? mobile)(context);
          case ScreenSize.mobile:
            return mobile(context);
        }
      },
    );
  }
}

/// Centra el contenido y limita su ancho máximo.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
