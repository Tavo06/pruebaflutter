import 'package:flutter_test/flutter_test.dart';
import 'package:proyectoflutter/exercises/finanzas/models/movimiento.dart';
import 'package:proyectoflutter/exercises/finanzas/providers/movimientos_provider.dart';

Movimiento _mov(TipoMovimiento tipo, String categoria, double monto) =>
    Movimiento(
      tipo: tipo,
      categoria: categoria,
      descripcion: 'Prueba',
      monto: monto,
      fecha: DateTime(2026, 1, 1),
    );

void main() {
  test('calcula ingresos, gastos, saldo y totales por categoría', () {
    final prov = MovimientosProvider(conDatosDeEjemplo: false);
    var avisos = 0;
    prov.addListener(() => avisos++);

    prov.agregar(_mov(TipoMovimiento.ingreso, 'Sueldo', 1000));
    prov.agregar(_mov(TipoMovimiento.gasto, 'Alimentación', 200));
    prov.agregar(_mov(TipoMovimiento.gasto, 'Alimentación', 50));
    prov.agregar(_mov(TipoMovimiento.gasto, 'Transporte', 30));

    expect(avisos, 4);
    expect(prov.totalIngresos, 1000);
    expect(prov.totalGastos, 280);
    expect(prov.saldo, 720);
    expect(prov.totalesPorCategoria(TipoMovimiento.gasto),
        {'Alimentación': 250, 'Transporte': 30});

    prov.eliminar(prov.filtrar(TipoMovimiento.ingreso).first.id);
    expect(prov.saldo, -280);
  });
}
