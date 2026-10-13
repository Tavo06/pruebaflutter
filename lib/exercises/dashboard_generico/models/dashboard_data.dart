import 'package:flutter/material.dart';

/// Indicador resumido (tarjeta KPI): p. ej. «Ventas del mes: 12 450».
/// EDITAR: cambia los campos según lo que pida tu ejercicio.
class KpiItem {
  const KpiItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.change,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  /// Variación porcentual frente al periodo anterior (positiva o negativa).
  final double? change;
}

/// Un punto del gráfico de barras (etiqueta + valor).
class ChartPoint {
  const ChartPoint(this.label, this.value);

  final String label;
  final double value;
}

/// Un elemento de la lista de «Actividad reciente».
class ActivityItem {
  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

/// Una fila de la tabla de resumen.
class TableRowData {
  const TableRowData({
    required this.name,
    required this.category,
    required this.amount,
    required this.status,
  });

  final String name;
  final String category;
  final double amount;
  final String status;
}
