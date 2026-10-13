import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/dashboard_data.dart';

/// Contenedor con título usado por cada bloque del dashboard.
class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Tarjeta KPI: icono, título, valor y variación.
class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.item});

  final KpiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = item.change;
    final up = (change ?? 0) >= 0;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(item.value,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis),
                  if (change != null)
                    Text(
                      '${up ? '▲' : '▼'} ${change.abs().toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: up ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de barras simple hecho solo con widgets (sin paquetes externos).
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.points, this.height = 180});

  final List<ChartPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = points.fold<double>(0, (m, p) => p.value > m ? p.value : m);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final p in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(p.value.toStringAsFixed(0),
                        style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: max == 0 ? 0 : p.value / max,
                        child: Tooltip(
                          message: '${p.label}: ${p.value.toStringAsFixed(0)}',
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.violet, AppColors.primary],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(p.label, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lista de actividad reciente.
class ActivityList extends StatelessWidget {
  const ActivityList({super.key, required this.items});

  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final a in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: a.color.withValues(alpha: 0.12),
              child: Icon(a.icon, color: a.color, size: 20),
            ),
            title: Text(a.title),
            subtitle: Text(a.subtitle),
          ),
      ],
    );
  }
}

/// Tabla de resumen con desplazamiento horizontal en pantallas pequeñas.
class SummaryTable extends StatelessWidget {
  const SummaryTable({super.key, required this.rows});

  final List<TableRowData> rows;

  Color _statusColor(String status) => switch (status) {
        'Activo' => AppColors.success,
        'Bajo stock' => AppColors.warning,
        _ => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Monto'), numeric: true),
          DataColumn(label: Text('Estado')),
        ],
        rows: [
          for (final r in rows)
            DataRow(cells: [
              DataCell(Text(r.name)),
              DataCell(Text(r.category)),
              DataCell(Text('S/ ${r.amount.toStringAsFixed(2)}')),
              DataCell(Text(r.status,
                  style: TextStyle(
                      color: _statusColor(r.status),
                      fontWeight: FontWeight.w600))),
            ]),
        ],
      ),
    );
  }
}
