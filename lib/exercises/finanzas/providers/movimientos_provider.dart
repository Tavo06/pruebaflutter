import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/movimiento.dart';

/// Estado GLOBAL de los movimientos (Provider + ChangeNotifier).
///
/// Se registra una sola vez en `lib/main.dart` (MultiProvider), por eso todas
/// las pantallas (resumen, lista, categorías, formulario) leen y modifican la
/// MISMA colección. Cada vez que cambia se llama a [notifyListeners] y todos
/// los `Consumer<MovimientosProvider>` se redibujan automáticamente.
class MovimientosProvider extends ChangeNotifier {
  MovimientosProvider({bool conDatosDeEjemplo = true}) {
    // EDITAR: pon `conDatosDeEjemplo: false` en main.dart para empezar vacío.
    if (conDatosDeEjemplo) _cargarEjemplos();
  }

  /// Colección privada: solo se modifica desde los métodos de esta clase.
  final List<Movimiento> _movimientos = [];

  /// Vista de solo lectura, ordenada del más reciente al más antiguo.
  UnmodifiableListView<Movimiento> get movimientos {
    final copia = [..._movimientos]..sort((a, b) => b.fecha.compareTo(a.fecha));
    return UnmodifiableListView(copia);
  }

  int get cantidad => _movimientos.length;
  bool get estaVacio => _movimientos.isEmpty;

  // ---------------------------------------------------------------------------
  // Operaciones sobre la colección
  // ---------------------------------------------------------------------------

  void agregar(Movimiento movimiento) {
    _movimientos.add(movimiento);
    notifyListeners(); // avisa a todos los Consumer
  }

  void eliminar(String id) {
    _movimientos.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Cálculos con operadores, condicionales y bucles
  // ---------------------------------------------------------------------------

  /// Suma de todos los ingresos (bucle for-in + condicional if).
  double get totalIngresos {
    double total = 0;
    for (final m in _movimientos) {
      if (m.tipo == TipoMovimiento.ingreso) {
        total += m.monto;
      }
    }
    return total;
  }

  /// Suma de todos los gastos (bucle for clásico con índice).
  double get totalGastos {
    double total = 0;
    for (int i = 0; i < _movimientos.length; i++) {
      if (_movimientos[i].esGasto) {
        total += _movimientos[i].monto;
      }
    }
    return total;
  }

  /// Saldo disponible = ingresos − gastos (operador aritmético).
  double get saldo => totalIngresos - totalGastos;

  /// Porcentaje de los ingresos que ya se gastó (0 a 100).
  double get porcentajeGastado {
    if (totalIngresos == 0) return totalGastos > 0 ? 100 : 0;
    final p = totalGastos / totalIngresos * 100;
    return p > 100 ? 100 : p;
  }

  /// Totales por categoría para un tipo. Devuelve un mapa ordenado de mayor a
  /// menor, p. ej. {'Alimentación': 450.0, 'Transporte': 120.0}.
  Map<String, double> totalesPorCategoria(TipoMovimiento tipo) {
    final totales = <String, double>{};
    for (final m in _movimientos) {
      if (m.tipo != tipo) continue; // se salta los del otro tipo
      // Si la categoría ya existe suma; si no, empieza desde 0 (operador ??).
      totales[m.categoria] = (totales[m.categoria] ?? 0) + m.monto;
    }
    final ordenadas = totales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(ordenadas);
  }

  /// Filtra la lista por tipo; `null` devuelve todos.
  List<Movimiento> filtrar(TipoMovimiento? tipo) {
    if (tipo == null) return movimientos;
    final resultado = <Movimiento>[];
    for (final m in movimientos) {
      if (m.tipo == tipo) resultado.add(m);
    }
    return resultado;
  }

  /// Los últimos [n] movimientos (para el resumen de Inicio).
  List<Movimiento> ultimos(int n) => movimientos.take(n).toList();

  // ---------------------------------------------------------------------------

  void _cargarEjemplos() {
    final hoy = DateTime.now();
    DateTime hace(int dias) => DateTime(hoy.year, hoy.month, hoy.day - dias);
    _movimientos.addAll([
      Movimiento(
          categoria: 'Sueldo',
          descripcion: 'Pago mensual',
          monto: 2500,
          fecha: hace(10),
          tipo: TipoMovimiento.ingreso),
      Movimiento(
          categoria: 'Freelance',
          descripcion: 'Diseño de logo',
          monto: 400,
          fecha: hace(4),
          tipo: TipoMovimiento.ingreso),
      Movimiento(
          categoria: 'Vivienda',
          descripcion: 'Alquiler',
          monto: 900,
          fecha: hace(9),
          tipo: TipoMovimiento.gasto),
      Movimiento(
          categoria: 'Alimentación',
          descripcion: 'Supermercado',
          monto: 320.5,
          fecha: hace(6),
          tipo: TipoMovimiento.gasto),
      Movimiento(
          categoria: 'Transporte',
          descripcion: 'Recarga de tarjeta',
          monto: 60,
          fecha: hace(3),
          tipo: TipoMovimiento.gasto),
      Movimiento(
          categoria: 'Ocio',
          descripcion: 'Cine',
          monto: 45,
          fecha: hace(1),
          tipo: TipoMovimiento.gasto),
    ]);
  }
}
