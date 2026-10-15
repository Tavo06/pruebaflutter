import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum StatusType { success, info, warning, error }

/// Mensaje en línea para éxitos, avisos y errores generales de un formulario.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.message, required this.type});

  final String message;
  final StatusType type;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final (Color color, IconData icon) = switch (type) {
      StatusType.success => (palette.success, Icons.check_circle_rounded),
      StatusType.info => (scheme.primary, Icons.info_rounded),
      StatusType.warning => (palette.warning, Icons.warning_amber_rounded),
      StatusType.error => (scheme.error, Icons.error_rounded),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
