import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/utils/app_exception.dart';
import '../../core/validators/validators.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/status_banner.dart';

/// Datos personales. Nombre y apellido son editables; DNI, fecha de
/// nacimiento y correo son de solo lectura (las reglas de Firestore impiden
/// modificarlos).
class MyDataScreen extends StatefulWidget {
  const MyDataScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends State<MyDataScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl = TextEditingController(text: widget.profile.nombre);
  late final _apellidoCtrl = TextEditingController(
    text: widget.profile.apellido,
  );
  bool _saving = false;
  String? _message;
  StatusType _messageType = StatusType.success;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    super.dispose();
  }

  bool get _changed =>
      Validators.normalizeName(_nombreCtrl.text) != widget.profile.nombre ||
      Validators.normalizeName(_apellidoCtrl.text) != widget.profile.apellido;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _message = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final nombre = Validators.normalizeName(_nombreCtrl.text);
      final apellido = Validators.normalizeName(_apellidoCtrl.text);
      await context.read<AuthProvider>().updateNames(
        nombre: nombre,
        apellido: apellido,
      );
      if (mounted) {
        _nombreCtrl.text = nombre;
        _apellidoCtrl.text = apellido;
        setState(() {
          _message = 'Tus datos se guardaron correctamente.';
          _messageType = StatusType.success;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message;
          _messageType = StatusType.error;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.isMobile(context);
    final p = widget.profile;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(mobile ? 16 : 28),
      child: MaxWidthBox(
        maxWidth: 820,
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(mobile ? 20 : 28),
            child: Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Datos personales', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Puedes actualizar tu nombre y apellido. Para modificar '
                    'los demás datos, contacta al administrador.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  if (_message != null) ...[
                    StatusBanner(message: _message!, type: _messageType),
                    const SizedBox(height: 16),
                  ],
                  _TwoColumns(
                    left: CustomTextField(
                      label: 'Nombre',
                      icon: Icons.badge_outlined,
                      controller: _nombreCtrl,
                      validator: Validators.firstName,
                      maxLength: AppConstants.maxNameLength,
                      textCapitalization: TextCapitalization.words,
                      enabled: !_saving,
                    ),
                    right: CustomTextField(
                      label: 'Apellido',
                      icon: Icons.badge_outlined,
                      controller: _apellidoCtrl,
                      validator: Validators.lastName,
                      maxLength: AppConstants.maxNameLength,
                      textCapitalization: TextCapitalization.words,
                      enabled: !_saving,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TwoColumns(
                    left: _ReadOnlyField(
                      label: 'DNI',
                      icon: Icons.credit_card_outlined,
                      value: p.dni,
                    ),
                    right: _ReadOnlyField(
                      label: 'Fecha de nacimiento',
                      icon: Icons.calendar_today_outlined,
                      value: DateFormat('dd/MM/yyyy').format(p.fechaNacimiento),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ReadOnlyField(
                    label: 'Correo electrónico',
                    icon: Icons.mail_outline_rounded,
                    value: p.correo,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: mobile
                        ? Alignment.center
                        : Alignment.centerRight,
                    child: SizedBox(
                      width: mobile ? double.infinity : 220,
                      child: PrimaryButton(
                        label: 'Guardar cambios',
                        icon: Icons.save_outlined,
                        loading: _saving,
                        onPressed: _changed ? _save : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 520) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label,
      icon: icon,
      initialValue: value,
      enabled: false,
      suffix: const Icon(Icons.lock_outline_rounded, size: 18),
    );
  }
}
