import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/responsive_layout.dart';
import '../models/movimiento.dart';
import '../providers/movimientos_provider.dart';
import '../utils/formatos.dart';

/// Contenedor de cada sección del menú (Nuevo, Historial, Resumen): agrega
/// el desplazamiento, los márgenes y el ancho máximo igual que «Inicio».
class VistaSeccion extends StatelessWidget {
  const VistaSeccion({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(mobile ? 16 : 28),
      child: MaxWidthBox(maxWidth: maxWidth, child: child),
    );
  }
}

/// Tarjeta con título usada por cada bloque.
class SeccionCard extends StatelessWidget {
  const SeccionCard({
    super.key,
    required this.titulo,
    required this.child,
    this.accion,
  });

  final String titulo;
  final Widget child;

  /// Botón opcional a la derecha del título (p. ej. «Ver todo»).
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(titulo,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                ?accion,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de un indicador: icono, título y valor.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(valor,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
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

/// Resumen de ingresos, gastos y saldo.
///
/// Usa `Consumer<MovimientosProvider>`: cuando se agrega o elimina un
/// movimiento en CUALQUIER pantalla, solo este bloque se vuelve a construir
/// con los totales actualizados.
class ResumenFinanciero extends StatelessWidget {
  const ResumenFinanciero({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MovimientosProvider>(
      builder: (context, prov, _) {
        final saldo = prov.saldo;
        final tarjetas = [
          KpiCard(
            titulo: 'Ingresos',
            valor: Formatos.moneda(prov.totalIngresos),
            icono: TipoMovimiento.ingreso.icono,
            color: TipoMovimiento.ingreso.color,
          ),
          KpiCard(
            titulo: 'Gastos',
            valor: Formatos.moneda(prov.totalGastos),
            icono: TipoMovimiento.gasto.icono,
            color: TipoMovimiento.gasto.color,
          ),
          KpiCard(
            titulo: 'Saldo disponible',
            valor: Formatos.moneda(saldo),
            icono: Icons.account_balance_wallet_outlined,
            // Condicional: saldo negativo en rojo, positivo en azul.
            color: saldo < 0 ? AppColors.error : AppColors.primary,
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, c) {
                const gap = 12.0;
                // 3 columnas si hay espacio; si no, una debajo de otra.
                final columnas = c.maxWidth >= 640 ? 3 : 1;
                final ancho = (c.maxWidth - gap * (columnas - 1)) / columnas;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final t in tarjetas) SizedBox(width: ancho, child: t),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _BarraGastado(porcentaje: prov.porcentajeGastado),
          ],
        );
      },
    );
  }
}

class _BarraGastado extends StatelessWidget {
  const _BarraGastado({required this.porcentaje});

  final double porcentaje;

  @override
  Widget build(BuildContext context) {
    final color = porcentaje >= 90
        ? AppColors.error
        : porcentaje >= 70
            ? AppColors.warning
            : AppColors.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Has gastado el ${porcentaje.toStringAsFixed(0)}% de tus ingresos',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: porcentaje / 100,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

/// Fila de un movimiento dentro de una lista.
class MovimientoTile extends StatelessWidget {
  const MovimientoTile({super.key, required this.movimiento, this.onEliminar});

  final Movimiento movimiento;
  final VoidCallback? onEliminar;

  @override
  Widget build(BuildContext context) {
    final m = movimiento;
    final signo = m.esIngreso ? '+' : '−';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: m.tipo.color.withValues(alpha: 0.12),
        child: Icon(m.tipo.icono, color: m.tipo.color, size: 20),
      ),
      title: Text(m.descripcion, overflow: TextOverflow.ellipsis),
      subtitle: Text('${m.categoria} · ${Formatos.fecha(m.fecha)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$signo ${Formatos.moneda(m.monto)}',
            style: TextStyle(
                color: m.tipo.color, fontWeight: FontWeight.w700),
          ),
          if (onEliminar != null)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onEliminar,
            ),
        ],
      ),
    );
  }
}

/// Barras horizontales de totales por categoría.
class BarrasCategorias extends StatelessWidget {
  const BarrasCategorias({
    super.key,
    required this.totales,
    required this.color,
  });

  final Map<String, double> totales;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (totales.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Sin movimientos de este tipo.'),
      );
    }
    // Bucle para hallar el mayor valor y escalar las barras.
    double maximo = 0;
    for (final v in totales.values) {
      if (v > maximo) maximo = v;
    }
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final e in totales.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(e.key)),
                    Text(Formatos.moneda(e.value),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: maximo == 0 ? 0 : e.value / maximo,
                    minHeight: 8,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Mensaje cuando no hay datos.
class SinMovimientos extends StatelessWidget {
  const SinMovimientos({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 40),
          SizedBox(height: 8),
          Text('Aún no registras movimientos.'),
        ],
      ),
    );
  }
}
