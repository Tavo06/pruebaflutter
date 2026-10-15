import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

/// Logotipo creado con Flutter (sin imágenes externas): una hoja sobre fondo
/// verde oliva con un punto terracota como acento.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.showName = true,
    this.nameColor,
    this.inverted = false,
  });

  final double size;
  final bool showName;
  final Color? nameColor;

  /// Versión clara para fondos oscuros (barra lateral, panel del login).
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final bg = inverted ? palette.onSidebar.withValues(alpha: 0.12) : scheme.primary;
    final fg = inverted ? palette.onSidebar : scheme.onPrimary;

    final mark = SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(size * 0.28),
            ),
            child: Icon(Icons.eco_outlined, color: fg, size: size * 0.56),
          ),
          Positioned(
            right: size * 0.14,
            top: size * 0.14,
            child: Container(
              width: size * 0.16,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: palette.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );

    if (!showName) return Semantics(label: AppConstants.appName, child: mark);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.3),
        Flexible(
          child: Text(
            AppConstants.appName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size * 0.48,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: nameColor ?? scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
