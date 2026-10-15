import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// =============================================================================
//  PUNTO DE ENTRADA DEL EJERCICIO
// =============================================================================
//
//  Este es el ÚNICO archivo que hay que tocar para mostrar un ejercicio en el
//  dashboard. Sustituye `WorkspacePlaceholder()` por la página del ejercicio:
//
//      import '../../exercises/mi_ejercicio/mi_ejercicio_page.dart';
//      ...
//      Widget build(BuildContext context) => const MiEjercicioPage();
//
//  No hace falta modificar el login, el registro, Firebase ni la navegación.
//  Ver `lib/exercises/README.md` y `lib/guia/practica.dart`.
// =============================================================================

/// Contenido central de la sección «Inicio».
class ExerciseModule extends StatelessWidget {
  const ExerciseModule({super.key});

  @override
  Widget build(BuildContext context) => const WorkspacePlaceholder();
}

/// Espacio de trabajo vacío: indica dónde se desarrollará el ejercicio.
class WorkspacePlaceholder extends StatelessWidget {
  const WorkspacePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Container(
      key: const Key('workspace_placeholder'),
      constraints: const BoxConstraints(minHeight: 320),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: palette.subtleFill,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                Icons.grid_view_rounded,
                size: 28,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Espacio de trabajo',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                'Aquí podrás implementar el ejercicio que necesites.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
