import '../models/servicio_transporte.dart';

/// Tarifa de un tipo de vehículo.
typedef TarifaVehiculo = ({double base, double precioKm, int capacidad});

/// Reglas de tarifas, recargos, descuentos y promociones del servicio.
///
/// Es lógica pura de Dart (sin Flutter ni Firebase) para poder probarla de
/// forma aislada.
class CalculadoraTarifas {
  CalculadoraTarifas._();

  // ---------------------------------------------------------------------------
  // Constantes de negocio
  // ---------------------------------------------------------------------------

  /// Ningún servicio cobra menos que esta tarifa (S/).
  static const double tarifaMinima = 7.00;

  static const double distanciaMaximaKm = 300;
  static const double peajeMaximo = 200;

  /// Pasajeros incluidos en la tarifa; desde el siguiente se cobra recargo.
  static const int pasajerosIncluidos = 2;
  static const double recargoPorPasajero = 1.50;

  static const double recargoNocturno = 0.20; // 20 %
  static const double recargoHoraPunta = 0.15; // 15 %

  /// Viajes de más de estos kilómetros tienen descuento por larga distancia.
  static const double kmLargaDistancia = 40;
  static const double descuentoLargaDistancia = 0.05; // 5 %

  /// Códigos de promoción admitidos.
  static const String codigoBienvenida = 'BIENVENIDA';
  static const String codigoNoche = 'NOCHE10';
  static const String codigoGrupo = 'GRUPO15';
  static const String codigoAhorro = 'AHORRA5';

  static const double descuentoBienvenida = 0.20; // 20 %
  static const double topeBienvenida = 15.00;
  static const double descuentoNoche = 0.10; // 10 %
  static const double descuentoGrupo = 0.15; // 15 %
  static const int pasajerosGrupo = 4;
  static const double montoAhorro = 5.00;
  static const double subtotalMinimoAhorro = 20.00;

  static const List<String> codigosValidos = [
    codigoBienvenida,
    codigoNoche,
    codigoGrupo,
    codigoAhorro,
  ];

  // ---------------------------------------------------------------------------
  // Tarifas y franjas
  // ---------------------------------------------------------------------------

  /// Tarifa base, precio por kilómetro y capacidad de cada vehículo.
  static TarifaVehiculo tarifaPara(TipoVehiculo vehiculo) {
    switch (vehiculo) {
      case TipoVehiculo.economico:
        return (base: 4.00, precioKm: 1.20, capacidad: 4);
      case TipoVehiculo.estandar:
        return (base: 5.00, precioKm: 1.50, capacidad: 4);
      case TipoVehiculo.premium:
        return (base: 8.00, precioKm: 2.20, capacidad: 4);
      case TipoVehiculo.van:
        return (base: 10.00, precioKm: 2.00, capacidad: 8);
    }
  }

  /// Nocturna: de 22:00 a 05:59. Hora punta: de 07:00 a 08:59 y de 17:00 a
  /// 19:59. El resto del día es tarifa normal.
  static FranjaHoraria franjaPara(int hora) {
    if (hora >= 22 || hora < 6) {
      return FranjaHoraria.nocturna;
    } else if ((hora >= 7 && hora < 9) || (hora >= 17 && hora < 20)) {
      return FranjaHoraria.horaPunta;
    } else {
      return FranjaHoraria.normal;
    }
  }

  // ---------------------------------------------------------------------------
  // Validaciones (devuelven el mensaje de error o `null` si es válido)
  // ---------------------------------------------------------------------------

  static String? validarDistancia(double? km) {
    if (km == null || km.isNaN || km.isInfinite) {
      return 'Ingresa una distancia numérica.';
    }
    if (km <= 0) return 'La distancia debe ser mayor que 0 km.';
    if (km > distanciaMaximaKm) {
      return 'La distancia no puede superar '
          '${distanciaMaximaKm.toStringAsFixed(0)} km.';
    }
    return null;
  }

  static String? validarPasajeros(int? pasajeros, TipoVehiculo vehiculo) {
    final capacidad = tarifaPara(vehiculo).capacidad;
    if (pasajeros == null) return 'Ingresa una cantidad entera de pasajeros.';
    if (pasajeros < 1) return 'Debe viajar al menos 1 pasajero.';
    if (pasajeros > capacidad) {
      return 'Un vehículo ${vehiculo.etiqueta} admite como máximo '
          '$capacidad pasajeros.';
    }
    return null;
  }

  static String? validarHora(int? hora) {
    if (hora == null || hora < 0 || hora > 23) {
      return 'La hora debe estar entre 0 y 23.';
    }
    return null;
  }

  static String? validarPeajes(double? monto) {
    if (monto == null || monto.isNaN || monto.isInfinite) {
      return 'Ingresa un monto numérico (0 si no hay peajes).';
    }
    if (monto < 0) return 'El monto de peajes no puede ser negativo.';
    if (monto > peajeMaximo) {
      return 'El monto de peajes no puede superar '
          'S/ ${peajeMaximo.toStringAsFixed(2)}.';
    }
    return null;
  }

  static String? validarCodigo(bool promocionVigente, String codigo) {
    if (!promocionVigente) return null;
    final normalizado = normalizarCodigo(codigo);
    if (normalizado.isEmpty) return 'Ingresa el código de la promoción.';
    if (!codigosValidos.contains(normalizado)) {
      return 'El código «$normalizado» no es válido.';
    }
    return null;
  }

  static String normalizarCodigo(String codigo) => codigo.trim().toUpperCase();

  /// Reúne todos los errores de un servicio. Lista vacía = servicio válido.
  static List<String> validar(ServicioTransporte s) => [
    ?validarDistancia(s.distanciaKm),
    ?validarHora(s.hora),
    ?validarPasajeros(s.pasajeros, s.vehiculo),
    ?validarPeajes(s.peajes),
    ?validarCodigo(s.promocionVigente, s.codigoPromocion),
  ];

  // ---------------------------------------------------------------------------
  // Cálculo
  // ---------------------------------------------------------------------------

  /// Calcula el costo de un servicio válido.
  ///
  /// Lanza [ArgumentError] si el servicio no supera las validaciones.
  static ResultadoServicio calcular(
    ServicioTransporte s, {
    required int numero,
  }) {
    final errores = validar(s);
    if (errores.isNotEmpty) throw ArgumentError(errores.join(' '));

    final tarifa = tarifaPara(s.vehiculo);
    final franja = franjaPara(s.hora);
    final observaciones = <String>[];

    // Subtotal: tarifa base + distancia × precio por kilómetro.
    var subtotal = tarifa.base + s.distanciaKm * tarifa.precioKm;
    if (subtotal < tarifaMinima) {
      subtotal = tarifaMinima;
      observaciones.add('Se aplicó la tarifa mínima.');
    }
    subtotal = redondear(subtotal);

    // Recargos.
    final recargos = <LineaDetalle>[];
    switch (franja) {
      case FranjaHoraria.nocturna:
        recargos.add(
          LineaDetalle(
            'Horario nocturno (+${_porcentaje(recargoNocturno)})',
            redondear(subtotal * recargoNocturno),
          ),
        );
      case FranjaHoraria.horaPunta:
        recargos.add(
          LineaDetalle(
            'Hora punta (+${_porcentaje(recargoHoraPunta)})',
            redondear(subtotal * recargoHoraPunta),
          ),
        );
      case FranjaHoraria.normal:
        break;
    }
    if (s.pasajeros > pasajerosIncluidos) {
      final adicionales = s.pasajeros - pasajerosIncluidos;
      recargos.add(
        LineaDetalle(
          'Pasajeros adicionales ($adicionales × '
          'S/ ${recargoPorPasajero.toStringAsFixed(2)})',
          redondear(adicionales * recargoPorPasajero),
        ),
      );
    }
    if (s.peajes > 0) {
      recargos.add(LineaDetalle('Peajes', redondear(s.peajes)));
    }

    // Descuentos.
    final descuentos = <LineaDetalle>[];
    if (s.distanciaKm > kmLargaDistancia) {
      descuentos.add(
        LineaDetalle(
          'Larga distancia (−${_porcentaje(descuentoLargaDistancia)})',
          redondear(subtotal * descuentoLargaDistancia),
        ),
      );
    }

    if (!s.promocionVigente) {
      observaciones.add('Sin promoción vigente.');
    } else {
      final promo = _aplicarPromocion(
        normalizarCodigo(s.codigoPromocion),
        subtotal: subtotal,
        franja: franja,
        pasajeros: s.pasajeros,
      );
      if (promo.linea != null) descuentos.add(promo.linea!);
      if (promo.observacion != null) observaciones.add(promo.observacion!);
    }

    final totalRecargos = recargos.fold(0.0, (a, l) => a + l.monto);
    final totalDescuentos = descuentos.fold(0.0, (a, l) => a + l.monto);
    var total = subtotal + totalRecargos - totalDescuentos;
    if (total < 0) total = 0;

    return ResultadoServicio(
      numero: numero,
      servicio: s,
      franja: franja,
      tarifaBase: tarifa.base,
      precioKm: tarifa.precioKm,
      subtotal: subtotal,
      recargos: recargos,
      descuentos: descuentos,
      total: redondear(total),
      observaciones: observaciones,
    );
  }

  /// Reglas de cada código. Devuelve la línea de descuento (si aplica) y una
  /// observación cuando el código es válido pero no cumple sus condiciones.
  static ({LineaDetalle? linea, String? observacion}) _aplicarPromocion(
    String codigo, {
    required double subtotal,
    required FranjaHoraria franja,
    required int pasajeros,
  }) {
    switch (codigo) {
      case codigoBienvenida:
        var monto = subtotal * descuentoBienvenida;
        final topado = monto > topeBienvenida;
        if (topado) monto = topeBienvenida;
        return (
          linea: LineaDetalle(
            'Promoción $codigo (−${_porcentaje(descuentoBienvenida)})',
            redondear(monto),
          ),
          observacion: topado
              ? 'La promoción $codigo tiene un tope de '
                    'S/ ${topeBienvenida.toStringAsFixed(2)}.'
              : null,
        );
      case codigoNoche:
        if (franja == FranjaHoraria.nocturna) {
          return (
            linea: LineaDetalle(
              'Promoción $codigo (−${_porcentaje(descuentoNoche)})',
              redondear(subtotal * descuentoNoche),
            ),
            observacion: null,
          );
        }
        return (
          linea: null,
          observacion: 'La promoción $codigo solo aplica en horario nocturno.',
        );
      case codigoGrupo:
        if (pasajeros >= pasajerosGrupo) {
          return (
            linea: LineaDetalle(
              'Promoción $codigo (−${_porcentaje(descuentoGrupo)})',
              redondear(subtotal * descuentoGrupo),
            ),
            observacion: null,
          );
        }
        return (
          linea: null,
          observacion:
              'La promoción $codigo requiere $pasajerosGrupo pasajeros o más.',
        );
      case codigoAhorro:
        if (subtotal >= subtotalMinimoAhorro) {
          return (
            linea: LineaDetalle('Promoción $codigo (−S/ 5.00)', montoAhorro),
            observacion: null,
          );
        }
        return (
          linea: null,
          observacion:
              'La promoción $codigo requiere un subtotal mínimo de '
              'S/ ${subtotalMinimoAhorro.toStringAsFixed(2)}.',
        );
      default:
        // No se alcanza: validar() rechaza los códigos desconocidos.
        return (linea: null, observacion: 'Código de promoción no válido.');
    }
  }

  /// Procesa varios servicios en una misma ejecución. Los válidos se calculan
  /// y los inválidos se rechazan con sus motivos.
  static ResultadoLote procesar(List<ServicioTransporte> servicios) {
    final procesados = <ResultadoServicio>[];
    final rechazados = <int, List<String>>{};

    for (var i = 0; i < servicios.length; i++) {
      final numero = i + 1;
      final errores = validar(servicios[i]);
      if (errores.isEmpty) {
        procesados.add(calcular(servicios[i], numero: numero));
      } else {
        rechazados[numero] = errores;
      }
    }
    return ResultadoLote(procesados: procesados, rechazados: rechazados);
  }

  /// Acumula los totales de los servicios calculados.
  static ResumenGeneral resumir(List<ResultadoServicio> resultados) {
    var subtotal = 0.0;
    var recargos = 0.0;
    var descuentos = 0.0;
    var total = 0.0;
    ResultadoServicio? mayor;
    final porVehiculo = <TipoVehiculo, int>{};

    for (final r in resultados) {
      subtotal += r.subtotal;
      recargos += r.totalRecargos;
      descuentos += r.totalDescuentos;
      total += r.total;
      if (mayor == null || r.total > mayor.total) mayor = r;
      porVehiculo[r.servicio.vehiculo] =
          (porVehiculo[r.servicio.vehiculo] ?? 0) + 1;
    }

    return ResumenGeneral(
      cantidad: resultados.length,
      subtotal: redondear(subtotal),
      recargos: redondear(recargos),
      descuentos: redondear(descuentos),
      total: redondear(total),
      servicioMayor: mayor,
      serviciosPorVehiculo: porVehiculo,
    );
  }

  /// Redondea a 2 decimales (céntimos).
  static double redondear(double valor) => (valor * 100).roundToDouble() / 100;

  /// Formato de moneda: `S/ 12.50`.
  static String soles(double monto) => 'S/ ${monto.toStringAsFixed(2)}';

  static String _porcentaje(double tasa) => '${(tasa * 100).round()} %';
}

/// Escenarios de ejemplo para demostrar varios casos en una ejecución,
/// incluido uno inválido que debe ser rechazado.
const List<ServicioTransporte> escenariosEjemplo = [
  ServicioTransporte(
    vehiculo: TipoVehiculo.economico,
    distanciaKm: 1.5,
    hora: 11,
    pasajeros: 1,
  ),
  ServicioTransporte(
    vehiculo: TipoVehiculo.estandar,
    distanciaKm: 12,
    hora: 18,
    pasajeros: 3,
    promocionVigente: true,
    codigoPromocion: 'BIENVENIDA',
  ),
  ServicioTransporte(
    vehiculo: TipoVehiculo.premium,
    distanciaKm: 25,
    hora: 23,
    pasajeros: 2,
    peajes: 6.5,
    promocionVigente: true,
    codigoPromocion: 'NOCHE10',
  ),
  ServicioTransporte(
    vehiculo: TipoVehiculo.van,
    distanciaKm: 60,
    hora: 8,
    pasajeros: 6,
    peajes: 13,
    promocionVigente: true,
    codigoPromocion: 'GRUPO15',
  ),
  ServicioTransporte(
    vehiculo: TipoVehiculo.estandar,
    distanciaKm: -4,
    hora: 14,
    pasajeros: 5,
  ),
];
