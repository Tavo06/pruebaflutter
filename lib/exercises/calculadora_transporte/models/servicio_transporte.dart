/// Tipos de vehículo disponibles en el servicio de transporte.
enum TipoVehiculo {
  economico('Económico'),
  estandar('Estándar'),
  premium('Premium'),
  van('Van');

  const TipoVehiculo(this.etiqueta);

  final String etiqueta;
}

/// Franja horaria que se deduce de la hora de inicio del servicio.
enum FranjaHoraria {
  normal('Normal'),
  horaPunta('Hora punta'),
  nocturna('Nocturna');

  const FranjaHoraria(this.etiqueta);

  final String etiqueta;
}

/// Datos de entrada de un servicio de transporte.
class ServicioTransporte {
  const ServicioTransporte({
    required this.vehiculo,
    required this.distanciaKm,
    required this.hora,
    required this.pasajeros,
    this.peajes = 0,
    this.promocionVigente = false,
    this.codigoPromocion = '',
  });

  final TipoVehiculo vehiculo;

  /// Distancia recorrida en kilómetros.
  final double distanciaKm;

  /// Hora de inicio del servicio (0 a 23).
  final int hora;
  final int pasajeros;

  /// Monto de peajes del recorrido, en soles.
  final double peajes;
  final bool promocionVigente;
  final String codigoPromocion;
}

/// Un concepto del detalle (recargo o descuento) con su monto en soles.
class LineaDetalle {
  const LineaDetalle(this.concepto, this.monto);

  final String concepto;
  final double monto;
}

/// Resultado del cálculo de un servicio.
class ResultadoServicio {
  const ResultadoServicio({
    required this.numero,
    required this.servicio,
    required this.franja,
    required this.tarifaBase,
    required this.precioKm,
    required this.subtotal,
    required this.recargos,
    required this.descuentos,
    required this.total,
    this.observaciones = const [],
  });

  /// Posición del servicio en la lista procesada (empieza en 1).
  final int numero;
  final ServicioTransporte servicio;
  final FranjaHoraria franja;
  final double tarifaBase;
  final double precioKm;
  final double subtotal;
  final List<LineaDetalle> recargos;
  final List<LineaDetalle> descuentos;
  final double total;
  final List<String> observaciones;

  double get totalRecargos =>
      recargos.fold(0, (suma, linea) => suma + linea.monto);

  double get totalDescuentos =>
      descuentos.fold(0, (suma, linea) => suma + linea.monto);
}

/// Resultado de procesar varios servicios en una misma ejecución.
class ResultadoLote {
  const ResultadoLote({required this.procesados, required this.rechazados});

  /// Servicios válidos con su cálculo.
  final List<ResultadoServicio> procesados;

  /// Servicios rechazados: número del servicio → motivos.
  final Map<int, List<String>> rechazados;
}

/// Totales acumulados de todos los servicios calculados.
class ResumenGeneral {
  const ResumenGeneral({
    required this.cantidad,
    required this.subtotal,
    required this.recargos,
    required this.descuentos,
    required this.total,
    required this.servicioMayor,
    required this.serviciosPorVehiculo,
  });

  final int cantidad;
  final double subtotal;
  final double recargos;
  final double descuentos;
  final double total;

  /// Servicio con el total más alto (`null` si no hay servicios).
  final ResultadoServicio? servicioMayor;
  final Map<TipoVehiculo, int> serviciosPorVehiculo;

  double get promedio => cantidad == 0 ? 0 : total / cantidad;
}
