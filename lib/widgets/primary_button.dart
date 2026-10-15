import 'package:flutter/material.dart';

/// Botón principal sobrio (verde oliva sólido) con estado de carga.
///
/// Mientras [loading] es `true` el botón ignora pulsaciones, evitando envíos
/// repetidos. El estilo viene de `filledButtonTheme` en `app_theme.dart`.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: onPrimary,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    return Semantics(
      button: true,
      enabled: onPressed != null && !loading,
      label: loading ? '$label, procesando' : label,
      excludeSemantics: true,
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: FilledButton(
          // Durante la carga se mantiene el color pleno pero sin acción.
          onPressed: onPressed == null ? null : (loading ? () {} : onPressed),
          child: content,
        ),
      ),
    );
  }
}
