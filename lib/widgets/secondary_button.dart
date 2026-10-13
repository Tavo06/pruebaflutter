import 'package:flutter/material.dart';

/// Botón secundario con borde y fondo neutro.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        : Text(label, overflow: TextOverflow.ellipsis);

    final button = icon != null && !loading
        ? OutlinedButton.icon(
            onPressed: loading ? null : onPressed,
            icon: Icon(icon, size: 20),
            label: child,
          )
        : OutlinedButton(onPressed: loading ? null : onPressed, child: child);

    return SizedBox(width: expand ? double.infinity : null, child: button);
  }
}
