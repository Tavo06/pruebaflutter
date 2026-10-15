import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/servicio_transporte.dart';
import '../services/calculadora_tarifas.dart';

/// Totales acumulados de todos los servicios calculados.
class ResumenGeneralCard extends StatelessWidget {
  const ResumenGeneralCard({super.key, required this.resumen});

  final ResumenGeneral resumen;

  /// «Estándar (2) · Van (1)», en el orden en que se declaran los vehículos.
  static String _porVehiculo(ResumenGeneral resumen) {
    final partes = <String>[];
    for (final v in TipoVehiculo.values) {
      final cantidad = resumen.serviciosPorVehiculo[v];
      if (cantidad != null) partes.add('${v.etiqueta} ($cantidad)');
    }
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final soles = CalculadoraTarifas.soles;
    final mayor = resumen.servicioMayor;

    final datos = <(String, String)>[
      ('Servicios calculados', '${resumen.cantidad}'),
      ('Suma de subtotales', soles(resumen.subtotal)),
      ('Total de recargos', '+ ${soles(resumen.recargos)}'),
      ('Total de descuentos', '− ${soles(resumen.descuentos)}'),
      ('Promedio por servicio', soles(resumen.promedio)),
      if (mayor != null)
        ('Servicio más caro', 'N.º ${mayor.numero} · ${soles(mayor.total)}'),
    ];

    return Container(
      key: const Key('resumen_general'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.subtleFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (etiqueta, valor) in datos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(etiqueta)),
                  Text(valor, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          if (resumen.serviciosPorVehiculo.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Por vehículo: ${_porVehiculo(resumen)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total general',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                soles(resumen.total),
                key: const Key('total_general'),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
