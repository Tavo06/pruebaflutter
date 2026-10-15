import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyectoflutter/core/theme/app_theme.dart';
import 'package:proyectoflutter/exercises/calculadora_transporte/calculadora_transporte_page.dart';
import 'package:proyectoflutter/exercises/calculadora_transporte/models/servicio_transporte.dart';
import 'package:proyectoflutter/exercises/calculadora_transporte/services/calculadora_tarifas.dart';
import 'package:proyectoflutter/screens/home/exercise_module.dart';

void main() {
  group('Franjas horarias', () {
    test('nocturna, hora punta y normal', () {
      expect(CalculadoraTarifas.franjaPara(23), FranjaHoraria.nocturna);
      expect(CalculadoraTarifas.franjaPara(0), FranjaHoraria.nocturna);
      expect(CalculadoraTarifas.franjaPara(5), FranjaHoraria.nocturna);
      expect(CalculadoraTarifas.franjaPara(6), FranjaHoraria.normal);
      expect(CalculadoraTarifas.franjaPara(7), FranjaHoraria.horaPunta);
      expect(CalculadoraTarifas.franjaPara(9), FranjaHoraria.normal);
      expect(CalculadoraTarifas.franjaPara(19), FranjaHoraria.horaPunta);
      expect(CalculadoraTarifas.franjaPara(20), FranjaHoraria.normal);
    });
  });

  group('Validaciones', () {
    test('distancia', () {
      expect(CalculadoraTarifas.validarDistancia(null), isNotNull);
      expect(CalculadoraTarifas.validarDistancia(0), isNotNull);
      expect(CalculadoraTarifas.validarDistancia(-3), isNotNull);
      expect(CalculadoraTarifas.validarDistancia(301), isNotNull);
      expect(CalculadoraTarifas.validarDistancia(double.nan), isNotNull);
      expect(CalculadoraTarifas.validarDistancia(12.5), isNull);
    });

    test('pasajeros según la capacidad del vehículo', () {
      expect(
        CalculadoraTarifas.validarPasajeros(0, TipoVehiculo.economico),
        isNotNull,
      );
      expect(
        CalculadoraTarifas.validarPasajeros(5, TipoVehiculo.economico),
        isNotNull,
      );
      expect(CalculadoraTarifas.validarPasajeros(5, TipoVehiculo.van), isNull);
      expect(
        CalculadoraTarifas.validarPasajeros(9, TipoVehiculo.van),
        isNotNull,
      );
      expect(
        CalculadoraTarifas.validarPasajeros(null, TipoVehiculo.van),
        isNotNull,
      );
    });

    test('hora, peajes y código', () {
      expect(CalculadoraTarifas.validarHora(24), isNotNull);
      expect(CalculadoraTarifas.validarHora(-1), isNotNull);
      expect(CalculadoraTarifas.validarHora(0), isNull);
      expect(CalculadoraTarifas.validarPeajes(-1), isNotNull);
      expect(CalculadoraTarifas.validarPeajes(201), isNotNull);
      expect(CalculadoraTarifas.validarPeajes(0), isNull);
      expect(CalculadoraTarifas.validarCodigo(false, 'XYZ'), isNull);
      expect(CalculadoraTarifas.validarCodigo(true, ''), isNotNull);
      expect(CalculadoraTarifas.validarCodigo(true, 'XYZ'), isNotNull);
      expect(CalculadoraTarifas.validarCodigo(true, ' noche10 '), isNull);
    });

    test('calcular rechaza servicios inválidos', () {
      const malo = ServicioTransporte(
        vehiculo: TipoVehiculo.estandar,
        distanciaKm: -4,
        hora: 10,
        pasajeros: 1,
      );
      expect(
        () => CalculadoraTarifas.calcular(malo, numero: 1),
        throwsArgumentError,
      );
    });
  });

  group('Cálculo de tarifas', () {
    test('tarifa mínima en viajes cortos', () {
      final r = CalculadoraTarifas.calcular(
        const ServicioTransporte(
          vehiculo: TipoVehiculo.economico,
          distanciaKm: 1.5,
          hora: 11,
          pasajeros: 1,
        ),
        numero: 1,
      );
      // 4.00 + 1.5 × 1.20 = 5.80 → tarifa mínima 7.00.
      expect(r.subtotal, 7.00);
      expect(r.recargos, isEmpty);
      expect(r.descuentos, isEmpty);
      expect(r.total, 7.00);
      expect(r.observaciones, contains('Se aplicó la tarifa mínima.'));
    });

    test('hora punta + pasajero adicional + BIENVENIDA', () {
      final r = CalculadoraTarifas.calcular(
        const ServicioTransporte(
          vehiculo: TipoVehiculo.estandar,
          distanciaKm: 12,
          hora: 18,
          pasajeros: 3,
          promocionVigente: true,
          codigoPromocion: 'bienvenida',
        ),
        numero: 2,
      );
      // Subtotal 5 + 12 × 1.50 = 23.00
      // Recargos: 15 % = 3.45; 1 pasajero adicional = 1.50 → 4.95
      // Descuento: 20 % = 4.60 → total 23.35
      expect(r.franja, FranjaHoraria.horaPunta);
      expect(r.subtotal, 23.00);
      expect(r.totalRecargos, closeTo(4.95, 0.001));
      expect(r.totalDescuentos, closeTo(4.60, 0.001));
      expect(r.total, 23.35);
    });

    test('nocturno + peajes + NOCHE10', () {
      final r = CalculadoraTarifas.calcular(
        const ServicioTransporte(
          vehiculo: TipoVehiculo.premium,
          distanciaKm: 25,
          hora: 23,
          pasajeros: 2,
          peajes: 6.5,
          promocionVigente: true,
          codigoPromocion: 'NOCHE10',
        ),
        numero: 3,
      );
      // Subtotal 8 + 25 × 2.20 = 63.00; nocturno 20 % = 12.60; peajes 6.50
      // NOCHE10 10 % = 6.30 → total 75.80
      expect(r.subtotal, 63.00);
      expect(r.totalRecargos, closeTo(19.10, 0.001));
      expect(r.totalDescuentos, closeTo(6.30, 0.001));
      expect(r.total, 75.80);
    });

    test('larga distancia + GRUPO15 en van', () {
      final r = CalculadoraTarifas.calcular(
        const ServicioTransporte(
          vehiculo: TipoVehiculo.van,
          distanciaKm: 60,
          hora: 14,
          pasajeros: 6,
          promocionVigente: true,
          codigoPromocion: 'GRUPO15',
        ),
        numero: 4,
      );
      // Subtotal 10 + 60 × 2 = 130.00; 4 pasajeros adicionales = 6.00
      // Larga distancia 5 % = 6.50; GRUPO15 15 % = 19.50 → total 110.00
      expect(r.subtotal, 130.00);
      expect(r.totalRecargos, closeTo(6.00, 0.001));
      expect(r.totalDescuentos, closeTo(26.00, 0.001));
      expect(r.total, 110.00);
    });

    test('promoción válida que no cumple condiciones no descuenta', () {
      final r = CalculadoraTarifas.calcular(
        const ServicioTransporte(
          vehiculo: TipoVehiculo.estandar,
          distanciaKm: 5,
          hora: 12,
          pasajeros: 1,
          promocionVigente: true,
          codigoPromocion: 'NOCHE10',
        ),
        numero: 1,
      );
      expect(r.descuentos, isEmpty);
      expect(r.total, 12.50);
      expect(
        r.observaciones.single,
        contains('solo aplica en horario nocturno'),
      );
    });

    test('BIENVENIDA respeta su tope y AHORRA5 su subtotal mínimo', () {
      final bienvenida = CalculadoraTarifas.calcular(
        const ServicioTransporte(
          vehiculo: TipoVehiculo.premium,
          distanciaKm: 100,
          hora: 12,
          pasajeros: 1,
          promocionVigente: true,
          codigoPromocion: 'BIENVENIDA',
        ),
        numero: 1,
      );
      // 20 % de 228.00 = 45.60 → tope 15.00
      expect(
        bienvenida.descuentos
            .firstWhere((d) => d.concepto.contains('BIENVENIDA'))
            .monto,
        CalculadoraTarifas.topeBienvenida,
      );

      final ahorro = CalculadoraTarifas.calcular(
        const ServicioTransporte(
          vehiculo: TipoVehiculo.economico,
          distanciaKm: 3,
          hora: 12,
          pasajeros: 1,
          promocionVigente: true,
          codigoPromocion: 'AHORRA5',
        ),
        numero: 2,
      );
      expect(ahorro.descuentos, isEmpty);
    });
  });

  group('Procesamiento de varios servicios', () {
    test('escenarios de ejemplo: válidos calculados e inválido rechazado', () {
      final lote = CalculadoraTarifas.procesar(escenariosEjemplo);
      expect(lote.procesados.length, 4);
      expect(lote.rechazados.keys, [5]);
      expect(lote.procesados.map((r) => r.numero), [1, 2, 3, 4]);

      final resumen = CalculadoraTarifas.resumir(lote.procesados);
      expect(resumen.cantidad, 4);
      // 7.00 + 23.35 + 75.80 + (130 + 19.50 + 6 + 13 − 6.50 − 19.50 = 142.50)
      expect(resumen.total, 248.65);
      expect(resumen.servicioMayor!.numero, 4);
      expect(resumen.serviciosPorVehiculo[TipoVehiculo.estandar], 1);
      expect(resumen.promedio, closeTo(62.1625, 0.0001));
    });

    test('resumen vacío', () {
      final resumen = CalculadoraTarifas.resumir(const []);
      expect(resumen.cantidad, 0);
      expect(resumen.total, 0);
      expect(resumen.promedio, 0);
      expect(resumen.servicioMayor, isNull);
    });
  });

  group('Interfaz', () {
    Widget app() => MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: SingleChildScrollView(child: CalculadoraTransportePage()),
      ),
    );

    Future<void> tamano(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('el módulo del dashboard muestra la calculadora', (
      tester,
    ) async {
      await tamano(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(child: ExerciseModule()),
          ),
        ),
      );
      expect(find.byType(CalculadoraTransportePage), findsOneWidget);
    });

    testWidgets('el espacio de trabajo base sigue disponible', (tester) async {
      await tamano(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: WorkspacePlaceholder()),
        ),
      );
      expect(find.byKey(const Key('workspace_placeholder')), findsOneWidget);
    });

    testWidgets('valida entradas inválidas en el formulario', (tester) async {
      await tamano(tester);
      await tester.pumpWidget(app());

      await tester.enterText(find.byKey(const Key('campo_distancia')), '-5');
      await tester.enterText(find.byKey(const Key('campo_pasajeros')), '9');
      await tester.enterText(find.byKey(const Key('campo_peajes')), '-1');
      await tester.tap(find.byKey(const Key('agregar_servicio')));
      await tester.pumpAndSettle();

      expect(
        find.text('La distancia debe ser mayor que 0 km.'),
        findsOneWidget,
      );
      expect(
        find.text('Un vehículo Estándar admite como máximo 4 pasajeros.'),
        findsOneWidget,
      );
      expect(
        find.text('El monto de peajes no puede ser negativo.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('pendiente_1')), findsNothing);
    });

    testWidgets('agrega servicios, calcula y muestra el resumen', (
      tester,
    ) async {
      await tamano(tester);
      await tester.pumpWidget(app());

      await tester.enterText(find.byKey(const Key('campo_distancia')), '10');
      await tester.enterText(find.byKey(const Key('campo_pasajeros')), '2');
      await tester.tap(find.byKey(const Key('agregar_servicio')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pendiente_1')), findsOneWidget);
      expect(find.text('Servicios por calcular (1)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cargar_ejemplos')));
      await tester.pumpAndSettle();
      expect(find.text('Servicios por calcular (6)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('calcular_servicios')));
      await tester.pumpAndSettle();

      // 1.er servicio: 5 + 10 × 1.50 = 20.00 a las 12:00, sin recargos.
      expect(find.byKey(const Key('resultado_1')), findsOneWidget);
      expect(find.byKey(const Key('resumen_general')), findsOneWidget);
      expect(find.byKey(const Key('servicios_rechazados')), findsOneWidget);
      expect(find.textContaining('N.º 6:'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('total_general'))).data,
        'S/ 268.65',
      );
      expect(find.textContaining('Servicios por calcular'), findsNothing);
    });
  });
}
