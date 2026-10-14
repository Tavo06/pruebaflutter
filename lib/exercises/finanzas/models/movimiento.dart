import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Tipo de movimiento. Es un enum «mejorado»: cada valor guarda su propia
/// etiqueta, icono, color y lista de categorías.
enum TipoMovimiento {
  ingreso(
    etiqueta: 'Ingreso',
    icono: Icons.south_west_rounded,
    color: AppColors.success,
    categorias: ['Sueldo', 'Ventas', 'Freelance', 'Regalo', 'Otros'],
  ),
  gasto(
    etiqueta: 'Gasto',
    icono: Icons.north_east_rounded,
    color: AppColors.error,
    categorias: [
      'Alimentación',
      'Transporte',
      'Vivienda',
      'Servicios',
      'Salud',
      'Educación',
      'Ocio',
      'Otros',
    ],
  );

  const TipoMovimiento({
    required this.etiqueta,
    required this.icono,
    required this.color,
    required this.categorias,
  });

  final String etiqueta;
  final IconData icono;
  final Color color;

  /// EDITAR: categorías disponibles en el formulario para este tipo.
  final List<String> categorias;
}

/// Clase Movimiento (POO).
///
/// - Encapsulamiento: atributos `final` (inmutables) y validados con `assert`.
/// - Constructor con parámetros nombrados y requeridos.
/// - Getters calculados: [esIngreso], [esGasto], [montoConSigno].
/// - Métodos: [copyWith] y [toString] (sobrescrito con @override).
class Movimiento {
  Movimiento({
    String? id,
    required this.categoria,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    required this.tipo,
  })  : assert(monto > 0, 'El monto debe ser mayor que cero'),
        id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String categoria;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final TipoMovimiento tipo;

  bool get esIngreso => tipo == TipoMovimiento.ingreso;
  bool get esGasto => tipo == TipoMovimiento.gasto;

  /// Positivo si es ingreso y negativo si es gasto (operador ternario).
  double get montoConSigno => esIngreso ? monto : -monto;

  /// Devuelve una copia cambiando solo los campos indicados.
  Movimiento copyWith({
    String? categoria,
    String? descripcion,
    double? monto,
    DateTime? fecha,
    TipoMovimiento? tipo,
  }) {
    return Movimiento(
      id: id,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      tipo: tipo ?? this.tipo,
    );
  }

  @override
  String toString() =>
      'Movimiento(${tipo.etiqueta}, $categoria, $descripcion, $monto, $fecha)';
}
