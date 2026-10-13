import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Indicador de progreso del registro: Datos → Verificación → Contraseña.
class RegistrationSteps extends StatelessWidget {
  const RegistrationSteps({super.key, required this.current});

  /// Paso actual, empezando en 0.
  final int current;

  static const _labels = ['Datos', 'Verificación', 'Contraseña'];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final children = <Widget>[];
    for (var i = 0; i < _labels.length; i++) {
      final done = i < current;
      final active = i == current;
      final color = done
          ? palette.success
          : active
          ? AppColors.primary
          : palette.textSecondary;
      children.add(
        Expanded(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  color: done || active ? color : palette.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    done
                        ? Icons.check_circle_rounded
                        : active
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _labels[i],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (i < _labels.length - 1) children.add(const SizedBox(width: 8));
    }
    return Semantics(
      label: 'Paso ${current + 1} de ${_labels.length}: ${_labels[current]}',
      child: ExcludeSemantics(child: Row(children: children)),
    );
  }
}
