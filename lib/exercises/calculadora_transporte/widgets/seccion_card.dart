import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Tarjeta con título e icono, con el mismo estilo que el dashboard.
class SeccionCard extends StatelessWidget {
  const SeccionCard({
    super.key,
    required this.titulo,
    required this.icono,
    required this.child,
    this.accion,
  });

  final String titulo;
  final IconData icono;
  final Widget child;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    // Material (y no Container) para que los ListTile y switches internos
    // pinten su fondo y efecto de pulsación sobre la tarjeta.
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.subtleFill,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    icono,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(titulo, style: theme.textTheme.titleMedium),
                ),
                ?accion,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
