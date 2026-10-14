import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../screens/home/home_screen.dart';
import '../../../widgets/app_dialog.dart';
import '../models/movimiento.dart';
import '../providers/movimientos_provider.dart';
import '../widgets/finanzas_widgets.dart';

/// Sección «Historial»: lista general de movimientos con filtro por tipo y
/// opción de eliminar.
class HistorialView extends StatefulWidget {
  const HistorialView({super.key});

  @override
  State<HistorialView> createState() => _HistorialViewState();
}

class _HistorialViewState extends State<HistorialView> {
  /// `null` = todos.
  TipoMovimiento? _filtro;

  Future<void> _eliminar(Movimiento m) async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Eliminar movimiento',
      message: '¿Seguro que deseas eliminar «${m.descripcion}»?',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (ok && mounted) context.read<MovimientosProvider>().eliminar(m.id);
  }

  @override
  Widget build(BuildContext context) {
    return VistaSeccion(
      maxWidth: 860,
      child: SeccionCard(
        titulo: 'Todos los movimientos',
        accion: FilledButton.icon(
          onPressed: () => HomeScreen.irA(context, HomeSection.nuevo),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nuevo'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _filtro == null,
                  onSelected: (_) => setState(() => _filtro = null),
                ),
                for (final t in TipoMovimiento.values)
                  ChoiceChip(
                    label: Text('${t.etiqueta}s'),
                    selected: _filtro == t,
                    onSelected: (_) => setState(() => _filtro = t),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Consumer: la lista se redibuja al agregar o eliminar.
            Consumer<MovimientosProvider>(
              builder: (context, prov, _) {
                final lista = prov.filtrar(_filtro);
                if (lista.isEmpty) return const SinMovimientos();
                return Column(
                  children: [
                    for (final m in lista)
                      MovimientoTile(
                        movimiento: m,
                        onEliminar: () => _eliminar(m),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
