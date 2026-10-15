import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/servicio_transporte.dart';
import '../services/calculadora_tarifas.dart';

/// Detalle del cálculo de un servicio: subtotal, recargos, descuentos y total.
class ResultadoServicioCard extends StatelessWidget {
  const ResultadoServicioCard({super.key, required this.resultado});

  final ResultadoServicio resultado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final s = resultado.servicio;
    final soles = CalculadoraTarifas.soles;

    return Container(
      key: Key('resultado_${resultado.numero}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Servicio ${resultado.numero} · ${s.vehiculo.etiqueta}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                soles(resultado.total),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${s.distanciaKm.toStringAsFixed(1)} km · '
            '${s.hora.toString().padLeft(2, '0')}:00 '
            '(${resultado.franja.etiqueta}) · '
            '${s.pasajeros} pasajero${s.pasajeros == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const Divider(height: 24),
          _Fila(
            'Subtotal (${soles(resultado.tarifaBase)} + '
            '${s.distanciaKm.toStringAsFixed(1)} km × '
            '${soles(resultado.precioKm)})',
            soles(resultado.subtotal),
          ),
          for (final r in resultado.recargos)
            _Fila(r.concepto, '+ ${soles(r.monto)}', color: palette.warning),
          for (final d in resultado.descuentos)
            _Fila(d.concepto, '− ${soles(d.monto)}', color: palette.success),
          const Divider(height: 20),
          _Fila('Recargos', '+ ${soles(resultado.totalRecargos)}'),
          _Fila('Descuentos', '− ${soles(resultado.totalDescuentos)}'),
          _Fila('Total final', soles(resultado.total), destacado: true),
          if (resultado.observaciones.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final o in resultado.observaciones)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $o',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.concepto, this.valor, {this.color, this.destacado = false});

  final String concepto;
  final String valor;
  final Color? color;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estilo = destacado
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(concepto, style: estilo)),
          const SizedBox(width: 12),
          Text(valor, style: estilo?.copyWith(color: color)),
        ],
      ),
    );
  }
}
