import 'package:flutter/material.dart';

import '../../core/constants/breakpoints.dart';
import 'services/dashboard_service.dart';
import 'widgets/dashboard_widgets.dart';

/// Vista principal del dashboard genérico.
///
/// Estructura (de arriba hacia abajo):
///   1. Fila de tarjetas KPI (4 indicadores).
///   2. Gráfico de barras + Actividad reciente (lado a lado en escritorio).
///   3. Tabla de resumen.
///
/// Se muestra dentro de la sección «Inicio» (ya tiene scroll), por eso aquí
/// NO se usa ningún widget con scroll vertical propio.
class DashboardGenericoPage extends StatelessWidget {
  const DashboardGenericoPage({super.key});

  // EDITAR: cambia la fuente de datos por la de tu ejercicio.
  final DashboardService _service = const DashboardService();

  @override
  Widget build(BuildContext context) {
    final kpis = _service.getKpis();
    const gap = 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final size = screenSizeForWidth(width);

        // Columnas de KPIs según el ancho: 1 (móvil), 2 (tableta), 4 (escritorio).
        final kpiColumns = switch (size) {
          ScreenSize.mobile => width < 380 ? 1 : 2,
          ScreenSize.tablet => 2,
          ScreenSize.desktop => 4,
        };
        final kpiWidth = (width - gap * (kpiColumns - 1)) / kpiColumns;

        final chart = DashboardCard(
          title: 'Ventas de la semana', // EDITAR: título del gráfico
          child: SimpleBarChart(points: _service.getChart()),
        );
        final activity = DashboardCard(
          title: 'Actividad reciente', // EDITAR
          child: ActivityList(items: _service.getActivity()),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // 1. KPIs
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final k in kpis)
                  SizedBox(width: kpiWidth, child: KpiCard(item: k)),
              ],
            ),
            const SizedBox(height: gap),

            // 2. Gráfico + actividad
            if (size == ScreenSize.desktop)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: chart),
                    const SizedBox(width: gap),
                    Expanded(flex: 2, child: activity),
                  ],
                ),
              )
            else ...[
              chart,
              const SizedBox(height: gap),
              activity,
            ],
            const SizedBox(height: gap),

            // 3. Tabla
            DashboardCard(
              title: 'Resumen de productos', // EDITAR
              child: SummaryTable(rows: _service.getTable()),
            ),
          ],
        );
      },
    );
  }
}
