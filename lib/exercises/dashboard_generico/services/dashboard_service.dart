import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/dashboard_data.dart';

/// Fuente de datos del dashboard.
///
/// Hoy devuelve datos de EJEMPLO fijos. EDITAR: reemplázalos por los de tu
/// ejercicio, o lee de Firestore (ver sección 11 de lib/guia/practica.dart),
/// por ejemplo:
///
///   final snap = await FirebaseFirestore.instance
///       .collection('users').doc(uid).collection('ventas').get();
class DashboardService {
  const DashboardService();

  List<KpiItem> getKpis() => const [
        KpiItem(
          title: 'Ventas',
          value: 'S/ 12 450',
          icon: Icons.attach_money_rounded,
          color: AppColors.primary,
          change: 8.2,
        ),
        KpiItem(
          title: 'Pedidos',
          value: '326',
          icon: Icons.shopping_bag_outlined,
          color: AppColors.violet,
          change: 3.5,
        ),
        KpiItem(
          title: 'Clientes',
          value: '1 024',
          icon: Icons.people_alt_outlined,
          color: AppColors.success,
          change: 12.1,
        ),
        KpiItem(
          title: 'Devoluciones',
          value: '14',
          icon: Icons.assignment_return_outlined,
          color: AppColors.error,
          change: -2.4,
        ),
      ];

  List<ChartPoint> getChart() => const [
        ChartPoint('Lun', 1200),
        ChartPoint('Mar', 1850),
        ChartPoint('Mié', 1400),
        ChartPoint('Jue', 2100),
        ChartPoint('Vie', 2600),
        ChartPoint('Sáb', 1900),
        ChartPoint('Dom', 1400),
      ];

  List<ActivityItem> getActivity() => const [
        ActivityItem(
          title: 'Nuevo pedido #1045',
          subtitle: 'Hace 5 min',
          icon: Icons.receipt_long_outlined,
          color: AppColors.primary,
        ),
        ActivityItem(
          title: 'Cliente registrado',
          subtitle: 'Hace 20 min',
          icon: Icons.person_add_alt_1_outlined,
          color: AppColors.success,
        ),
        ActivityItem(
          title: 'Stock bajo: Producto C',
          subtitle: 'Hace 1 h',
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
        ),
        ActivityItem(
          title: 'Devolución #0987',
          subtitle: 'Hace 3 h',
          icon: Icons.undo_rounded,
          color: AppColors.error,
        ),
      ];

  List<TableRowData> getTable() => const [
        TableRowData(
            name: 'Producto A', category: 'Bebidas', amount: 3200, status: 'Activo'),
        TableRowData(
            name: 'Producto B', category: 'Snacks', amount: 2750, status: 'Activo'),
        TableRowData(
            name: 'Producto C', category: 'Limpieza', amount: 1980, status: 'Bajo stock'),
        TableRowData(
            name: 'Producto D', category: 'Bebidas', amount: 1540, status: 'Inactivo'),
      ];
}
