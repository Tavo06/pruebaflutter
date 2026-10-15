import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/status_banner.dart';
import 'models/servicio_transporte.dart';
import 'services/calculadora_tarifas.dart';
import 'widgets/resultado_servicio_card.dart';
import 'widgets/resumen_general_card.dart';
import 'widgets/seccion_card.dart';

/// Criterio de orden del resumen final.
enum _Orden { registro, mayorTotal }

/// Calculadora del costo final de servicios de transporte.
///
/// Flujo: se registran uno o varios servicios, se calculan todos en una misma
/// ejecución y se muestra el detalle de cada uno junto con el resumen general.
class CalculadoraTransportePage extends StatefulWidget {
  const CalculadoraTransportePage({super.key});

  @override
  State<CalculadoraTransportePage> createState() =>
      _CalculadoraTransportePageState();
}

class _CalculadoraTransportePageState extends State<CalculadoraTransportePage> {
  final _formKey = GlobalKey<FormState>();
  final _distancia = TextEditingController();
  final _pasajeros = TextEditingController(text: '1');
  final _peajes = TextEditingController(text: '0');
  final _codigo = TextEditingController();

  TipoVehiculo _vehiculo = TipoVehiculo.estandar;
  int _hora = 12;
  bool _promocionVigente = false;

  /// Servicios registrados pendientes de calcular.
  final List<ServicioTransporte> _pendientes = [];

  /// Resultados del último cálculo (colección de Dart en memoria).
  List<ResultadoServicio> _resultados = [];
  Map<int, List<String>> _rechazados = {};
  _Orden _orden = _Orden.registro;

  @override
  void dispose() {
    _distancia.dispose();
    _pasajeros.dispose();
    _peajes.dispose();
    _codigo.dispose();
    super.dispose();
  }

  static double? _decimal(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  void _agregar() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _pendientes.add(
        ServicioTransporte(
          vehiculo: _vehiculo,
          distanciaKm: _decimal(_distancia.text)!,
          hora: _hora,
          pasajeros: int.parse(_pasajeros.text.trim()),
          peajes: _decimal(_peajes.text)!,
          promocionVigente: _promocionVigente,
          codigoPromocion: _promocionVigente
              ? CalculadoraTarifas.normalizarCodigo(_codigo.text)
              : '',
        ),
      );
    });
    // reset() quita los errores y el estado «interactuado» de los campos;
    // después se dejan los valores por defecto para el siguiente servicio.
    _formKey.currentState!.reset();
    _distancia.clear();
    _pasajeros.text = '1';
    _peajes.text = '0';
    _codigo.clear();
  }

  void _cargarEjemplos() {
    setState(() => _pendientes.addAll(escenariosEjemplo));
  }

  void _calcular() {
    final lote = CalculadoraTarifas.procesar(_pendientes);
    setState(() {
      _resultados = lote.procesados;
      _rechazados = lote.rechazados;
      _pendientes.clear();
    });
  }

  void _limpiar() {
    setState(() {
      _pendientes.clear();
      _resultados = [];
      _rechazados = {};
    });
  }

  List<ResultadoServicio> get _resultadosOrdenados {
    final lista = [..._resultados];
    switch (_orden) {
      case _Orden.registro:
        lista.sort((a, b) => a.numero.compareTo(b.numero));
      case _Orden.mayorTotal:
        lista.sort((a, b) => b.total.compareTo(a.total));
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('calculadora_transporte'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _formulario(context),
        if (_pendientes.isNotEmpty) ...[
          const SizedBox(height: 20),
          _listaPendientes(context),
        ],
        if (_resultados.isNotEmpty || _rechazados.isNotEmpty) ...[
          const SizedBox(height: 20),
          _resumen(context),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Formulario
  // ---------------------------------------------------------------------------

  Widget _formulario(BuildContext context) {
    final campos = <Widget>[
      _Etiquetado(
        etiqueta: 'Tipo de vehículo',
        child: DropdownButtonFormField<TipoVehiculo>(
          key: const Key('campo_vehiculo'),
          initialValue: _vehiculo,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.directions_car_outlined, size: 20),
          ),
          items: [
            for (final v in TipoVehiculo.values)
              DropdownMenuItem(
                value: v,
                child: Text(
                  '${v.etiqueta} · '
                  '${CalculadoraTarifas.soles(CalculadoraTarifas.tarifaPara(v).precioKm)}/km',
                ),
              ),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _vehiculo = v);
            // La capacidad cambia con el vehículo: revalida los pasajeros.
            if (_pasajeros.text.isNotEmpty) _formKey.currentState?.validate();
          },
        ),
      ),
      CustomTextField(
        label: 'Distancia (km)',
        fieldKey: const Key('campo_distancia'),
        controller: _distancia,
        hint: 'Ej. 12.5',
        icon: Icons.route_outlined,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
        ],
        validator: (v) =>
            CalculadoraTarifas.validarDistancia(_decimal(v ?? '')),
      ),
      _Etiquetado(
        etiqueta: 'Hora de inicio',
        child: DropdownButtonFormField<int>(
          key: const Key('campo_hora'),
          initialValue: _hora,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.schedule_outlined, size: 20),
          ),
          items: [
            for (var h = 0; h < 24; h++)
              DropdownMenuItem(
                value: h,
                child: Text(
                  '${h.toString().padLeft(2, '0')}:00 · '
                  '${CalculadoraTarifas.franjaPara(h).etiqueta}',
                ),
              ),
          ],
          validator: CalculadoraTarifas.validarHora,
          onChanged: (h) {
            if (h != null) setState(() => _hora = h);
          },
        ),
      ),
      CustomTextField(
        label: 'Pasajeros',
        fieldKey: const Key('campo_pasajeros'),
        controller: _pasajeros,
        icon: Icons.people_outline,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
        validator: (v) => CalculadoraTarifas.validarPasajeros(
          int.tryParse((v ?? '').trim()),
          _vehiculo,
        ),
      ),
      CustomTextField(
        label: 'Peajes (S/)',
        fieldKey: const Key('campo_peajes'),
        controller: _peajes,
        icon: Icons.toll_outlined,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
        ],
        validator: (v) => CalculadoraTarifas.validarPeajes(_decimal(v ?? '')),
      ),
      CustomTextField(
        label: 'Código de promoción',
        fieldKey: const Key('campo_codigo'),
        controller: _codigo,
        icon: Icons.local_offer_outlined,
        hint: _promocionVigente ? 'Ej. BIENVENIDA' : 'Sin promoción vigente',
        enabled: _promocionVigente,
        textCapitalization: TextCapitalization.characters,
        validator: (v) =>
            CalculadoraTarifas.validarCodigo(_promocionVigente, v ?? ''),
      ),
    ];

    return SeccionCard(
      titulo: 'Nuevo servicio',
      icono: Icons.local_taxi_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final columnas = constraints.maxWidth >= 600 ? 2 : 1;
                final ancho =
                    (constraints.maxWidth - (columnas - 1) * 16) / columnas;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final c in campos) SizedBox(width: ancho, child: c),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('campo_promocion'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Promoción vigente'),
              subtitle: Text(
                'Códigos: ${CalculadoraTarifas.codigosValidos.join(', ')}',
              ),
              value: _promocionVigente,
              onChanged: (v) => setState(() {
                _promocionVigente = v;
                if (!v) _codigo.clear();
              }),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                PrimaryButton(
                  key: const Key('agregar_servicio'),
                  label: 'Agregar servicio',
                  icon: Icons.add_rounded,
                  expand: false,
                  onPressed: _agregar,
                ),
                SecondaryButton(
                  key: const Key('cargar_ejemplos'),
                  label: 'Cargar escenarios de ejemplo',
                  icon: Icons.playlist_add_rounded,
                  expand: false,
                  onPressed: _cargarEjemplos,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Servicios pendientes
  // ---------------------------------------------------------------------------

  Widget _listaPendientes(BuildContext context) {
    final palette = context.palette;
    return SeccionCard(
      titulo: 'Servicios por calcular (${_pendientes.length})',
      icono: Icons.list_alt_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _pendientes.length; i++)
            ListTile(
              key: Key('pendiente_${i + 1}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: palette.subtleFill,
                child: Text('${i + 1}'),
              ),
              title: Text(_pendientes[i].vehiculo.etiqueta),
              subtitle: Text(_describir(_pendientes[i])),
              trailing: IconButton(
                tooltip: 'Quitar',
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => setState(() => _pendientes.removeAt(i)),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              PrimaryButton(
                key: const Key('calcular_servicios'),
                label: 'Calcular servicios',
                icon: Icons.calculate_outlined,
                expand: false,
                onPressed: _calcular,
              ),
              SecondaryButton(
                label: 'Limpiar todo',
                icon: Icons.delete_sweep_outlined,
                expand: false,
                onPressed: _limpiar,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _describir(ServicioTransporte s) {
    final partes = [
      '${s.distanciaKm.toStringAsFixed(1)} km',
      '${s.hora.toString().padLeft(2, '0')}:00',
      '${s.pasajeros} pas.',
      if (s.peajes != 0) 'peajes ${CalculadoraTarifas.soles(s.peajes)}',
      if (s.promocionVigente) 'promo ${s.codigoPromocion}',
    ];
    return partes.join(' · ');
  }

  // ---------------------------------------------------------------------------
  // Resumen final
  // ---------------------------------------------------------------------------

  Widget _resumen(BuildContext context) {
    final resumen = CalculadoraTarifas.resumir(_resultados);
    return SeccionCard(
      titulo: 'Resumen de servicios',
      icono: Icons.receipt_long_outlined,
      accion: IconButton(
        tooltip: 'Limpiar resultados',
        icon: const Icon(Icons.delete_sweep_outlined),
        onPressed: _limpiar,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_rechazados.isNotEmpty) ...[
            StatusBanner(
              key: const Key('servicios_rechazados'),
              type: StatusType.error,
              message: [
                'Servicios rechazados por datos inválidos:',
                for (final e in _rechazados.entries)
                  'N.º ${e.key}: ${e.value.join(' ')}',
              ].join('\n'),
            ),
            const SizedBox(height: 16),
          ],
          if (_resultados.isNotEmpty) ...[
            ResumenGeneralCard(resumen: resumen),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<_Orden>(
                segments: const [
                  ButtonSegment(
                    value: _Orden.registro,
                    label: Text('N.º de servicio'),
                  ),
                  ButtonSegment(
                    value: _Orden.mayorTotal,
                    label: Text('Mayor total'),
                  ),
                ],
                selected: {_orden},
                onSelectionChanged: (s) => setState(() => _orden = s.first),
              ),
            ),
            const SizedBox(height: 12),
            for (final r in _resultadosOrdenados) ...[
              ResultadoServicioCard(resultado: r),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

/// Etiqueta superior con el mismo estilo que [CustomTextField].
class _Etiquetado extends StatelessWidget {
  const _Etiquetado({required this.etiqueta, required this.child});

  final String etiqueta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            etiqueta,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        child,
      ],
    );
  }
}
