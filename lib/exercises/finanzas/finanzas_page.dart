import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screens/home/home_screen.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import 'models/movimiento.dart';
import 'providers/movimientos_provider.dart';
import 'widgets/finanzas_widgets.dart';

/// Contenido del ejercicio en la sección «Inicio».
///
/// Navegación del ejercicio (menú lateral en escritorio / barra inferior en
/// móvil, definida en lib/screens/home/home_screen.dart → enum HomeSection):
///   Inicio → esta vista: resumen + últimos movimientos + gastos.
///   Nuevo movimiento → screens/nuevo_movimiento_view.dart (formulario).
///   Historial → screens/historial_view.dart (lista general).
///   Resumen → screens/resumen_view.dart (totales por categoría).
///
/// Todas leen el MISMO MovimientosProvider (estado global). Para cambiar de
/// sección desde un botón: HomeScreen.irA(context, HomeSection.historial).
///
/// Se muestra dentro de un scroll, por eso aquí no hay scroll propio.
class FinanzasPage extends StatelessWidget {
  const FinanzasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.sizeOf(context).width >= 1024;

    final ultimos = SeccionCard(
      titulo: 'Últimos movimientos',
      accion: TextButton(
        onPressed: () => HomeScreen.irA(context, HomeSection.historial),
        child: const Text('Ver todos'),
      ),
      child: Consumer<MovimientosProvider>(
        builder: (context, prov, _) {
          if (prov.estaVacio) return const SinMovimientos();
          return Column(
            children: [
              for (final m in prov.ultimos(5)) MovimientoTile(movimiento: m),
            ],
          );
        },
      ),
    );

    final gastos = SeccionCard(
      titulo: 'Gastos por categoría',
      accion: TextButton(
        onPressed: () => HomeScreen.irA(context, HomeSection.resumen),
        child: const Text('Detalle'),
      ),
      child: Consumer<MovimientosProvider>(
        builder: (context, prov, _) => BarrasCategorias(
          totales: prov.totalesPorCategoria(TipoMovimiento.gasto),
          color: TipoMovimiento.gasto.color,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),

        // 1. Resumen: ingresos, gastos y saldo (Consumer interno).
        const ResumenFinanciero(),
        const SizedBox(height: 16),

        // 2. Accesos rápidos a las otras secciones.
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 220,
              child: PrimaryButton(
                label: 'Nuevo movimiento',
                icon: Icons.add_rounded,
                onPressed: () => HomeScreen.irA(context, HomeSection.nuevo),
              ),
            ),
            SizedBox(
              width: 200,
              child: SecondaryButton(
                label: 'Historial',
                icon: Icons.receipt_long_outlined,
                onPressed: () =>
                    HomeScreen.irA(context, HomeSection.historial),
              ),
            ),
            SizedBox(
              width: 200,
              child: SecondaryButton(
                label: 'Resumen',
                icon: Icons.pie_chart_outline_rounded,
                onPressed: () => HomeScreen.irA(context, HomeSection.resumen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. Últimos movimientos + gastos por categoría
        if (esAncho)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: ultimos),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: gastos),
            ],
          )
        else ...[
          ultimos,
          const SizedBox(height: 16),
          gastos,
        ],
      ],
    );
  }
}
