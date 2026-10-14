import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../screens/home/home_screen.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../models/movimiento.dart';
import '../providers/movimientos_provider.dart';
import '../utils/formatos.dart';
import '../widgets/finanzas_widgets.dart';

/// Sección «Nuevo movimiento»: formulario VALIDADO para registrar un
/// ingreso o un gasto. Al guardar lleva al «Historial».
class NuevoMovimientoView extends StatefulWidget {
  const NuevoMovimientoView({super.key});

  @override
  State<NuevoMovimientoView> createState() => _NuevoMovimientoViewState();
}

class _NuevoMovimientoViewState extends State<NuevoMovimientoView> {
  final _formKey = GlobalKey<FormState>();
  final _descripcion = TextEditingController();
  final _monto = TextEditingController();
  final _fechaTexto = TextEditingController();

  TipoMovimiento _tipo = TipoMovimiento.gasto;
  String? _categoria;
  DateTime? _fecha;

  @override
  void initState() {
    super.initState();
    _ponerFecha(DateTime.now()); // por defecto, hoy
  }

  @override
  void dispose() {
    _descripcion.dispose();
    _monto.dispose();
    _fechaTexto.dispose();
    super.dispose();
  }

  void _ponerFecha(DateTime f) {
    _fecha = DateTime(f.year, f.month, f.day);
    _fechaTexto.text = Formatos.fecha(_fecha!);
  }

  // ---------------------------------------------------------------------------
  // Validaciones (EDITAR: ajusta límites y mensajes según tu ejercicio)
  // ---------------------------------------------------------------------------

  String? _validarDescripcion(String? v) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa una descripción.';
    if (texto.length < 3) return 'Mínimo 3 caracteres.';
    if (texto.length > 60) return 'Máximo 60 caracteres.';
    return null;
  }

  String? _validarMonto(String? v) {
    final texto = (v ?? '').trim().replaceAll(',', '.');
    if (texto.isEmpty) return 'Ingresa el monto.';
    final n = double.tryParse(texto);
    if (n == null) return 'Ingresa un número válido.';
    if (n <= 0) return 'El monto debe ser mayor que cero.';
    if (n > 1000000) return 'El monto no puede superar 1 000 000.';
    return null;
  }

  String? _validarFecha(String? _) {
    if (_fecha == null) return 'Selecciona la fecha.';
    final hoy = DateTime.now();
    if (_fecha!.isAfter(DateTime(hoy.year, hoy.month, hoy.day))) {
      return 'La fecha no puede ser futura.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (elegida != null) setState(() => _ponerFecha(elegida));
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final movimiento = Movimiento(
      tipo: _tipo,
      categoria: _categoria!,
      descripcion: _descripcion.text.trim(),
      monto: double.parse(_monto.text.trim().replaceAll(',', '.')),
      fecha: _fecha!,
    );

    // read(): modifica el estado global sin escuchar cambios aquí.
    context.read<MovimientosProvider>().agregar(movimiento);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_tipo.etiqueta} registrado correctamente.')),
    );
    // Navegación: después de guardar se muestra el historial.
    HomeScreen.irA(context, HomeSection.historial);
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(fontWeight: FontWeight.w600);

    return VistaSeccion(
      maxWidth: 560,
      child: SeccionCard(
        titulo: 'Registrar movimiento',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tipo
              Text('Tipo', style: labelStyle),
              const SizedBox(height: 6),
              SegmentedButton<TipoMovimiento>(
                segments: [
                  for (final t in TipoMovimiento.values)
                    ButtonSegment(
                      value: t,
                      label: Text(t.etiqueta),
                      icon: Icon(t.icono),
                    ),
                ],
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() {
                  _tipo = s.first;
                  _categoria = null; // las categorías cambian con el tipo
                }),
              ),
              const SizedBox(height: 16),

              // Categoría
              Text('Categoría', style: labelStyle),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                // La key fuerza a reiniciar el campo al cambiar de tipo.
                key: ValueKey(_tipo),
                initialValue: _categoria,
                // Ocupa el ancho disponible (evita desbordes en móvil).
                isExpanded: true,
                hint: const Text(
                  'Selecciona una categoría',
                  overflow: TextOverflow.ellipsis,
                ),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
                items: [
                  for (final c in _tipo.categorias)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _categoria = v),
                validator: (v) => v == null ? 'Selecciona una categoría.' : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Descripción',
                hint: 'Ej. Supermercado',
                icon: Icons.notes_outlined,
                controller: _descripcion,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: _validarDescripcion,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Monto (S/)',
                hint: '0.00',
                icon: Icons.payments_outlined,
                controller: _monto,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                validator: _validarMonto,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Fecha',
                icon: Icons.event_outlined,
                controller: _fechaTexto,
                readOnly: true,
                onTap: _elegirFecha,
                validator: _validarFecha,
              ),
              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Guardar ${_tipo.etiqueta.toLowerCase()}',
                icon: Icons.check_rounded,
                onPressed: _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
