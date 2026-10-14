import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movimiento.dart';
import '../providers/movimientos_provider.dart';
import '../widgets/finanzas_widgets.dart';

/// Sección «Resumen»: ingresos, gastos, saldo y totales por categoría.
class ResumenView extends StatelessWidget {
  const ResumenView({super.key});

  @override
  Widget build(BuildContext context) {
    return VistaSeccion(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Totales generales (Consumer interno).
          const ResumenFinanciero(),
          const SizedBox(height: 16),

          // Totales por categoría: lado a lado si hay espacio.
          Consumer<MovimientosProvider>(
            builder: (context, prov, _) {
              final tarjetas = [
                for (final tipo in TipoMovimiento.values)
                  SeccionCard(
                    titulo: '${tipo.etiqueta}s por categoría',
                    child: BarrasCategorias(
                      totales: prov.totalesPorCategoria(tipo),
                      color: tipo.color,
                    ),
                  ),
              ];
              return LayoutBuilder(
                builder: (context, c) => c.maxWidth >= 760
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: tarjetas[0]),
                          const SizedBox(width: 16),
                          Expanded(child: tarjetas[1]),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          tarjetas[0],
                          const SizedBox(height: 16),
                          tarjetas[1],
                        ],
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
