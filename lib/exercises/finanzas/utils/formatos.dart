import 'package:intl/intl.dart';

/// Formatos de moneda y fecha usados en todas las pantallas.
/// EDITAR: cambia el símbolo de moneda si tu ejercicio usa otro.
class Formatos {
  Formatos._();

  static final NumberFormat _moneda =
      NumberFormat.currency(locale: 'es', symbol: 'S/', decimalDigits: 2);
  static final DateFormat _fecha = DateFormat('dd/MM/yyyy');

  static String moneda(double valor) => _moneda.format(valor);
  static String fecha(DateTime valor) => _fecha.format(valor);
}
