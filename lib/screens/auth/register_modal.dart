import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_exception.dart';
import '../../core/validators/validators.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/registration_steps.dart';
import '../../widgets/status_banner.dart';

/// Paso 1 del registro: datos personales y correo.
///
/// Al pulsar «Continuar» se crea la cuenta pendiente y se envía el enlace de
/// verificación. El modal se cierra automáticamente cuando la aplicación pasa
/// a la pantalla de verificación.
class RegisterModal extends StatefulWidget {
  const RegisterModal({super.key});

  @override
  State<RegisterModal> createState() => _RegisterModalState();
}

class _RegisterModalState extends State<RegisterModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  DateTime? _fechaNacimiento;
  bool _loading = false;
  String? _emailError;
  String? _dniError;
  String? _generalError;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _dniCtrl.dispose();
    _fechaCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (_loading) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es'),
      initialDate: _fechaNacimiento ?? DateTime(now.year - 18, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      fieldHintText: 'dd/mm/aaaa',
      fieldLabelText: 'Fecha de nacimiento',
      errorFormatText: 'Usa el formato dd/mm/aaaa.',
      errorInvalidText: 'Ingresa una fecha válida y no futura.',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    setState(() {
      _fechaNacimiento = picked;
      _fechaCtrl.text = _dateFormat.format(picked);
    });
    _formKey.currentState?.validate();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() {
      _emailError = null;
      _dniError = null;
      _generalError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = RegistrationData(
      nombre: Validators.normalizeName(_nombreCtrl.text),
      apellido: Validators.normalizeName(_apellidoCtrl.text),
      dni: _dniCtrl.text.trim(),
      fechaNacimiento: _fechaNacimiento!,
      correo: Validators.normalizeEmail(_correoCtrl.text),
    );

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().startRegistration(data);
      // La navegación a la verificación la gestiona la app al cambiar el
      // estado; este modal se cierra automáticamente.
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        switch (e.field) {
          case ErrorField.email:
            _emailError = e.message;
          case ErrorField.dni:
            _dniError = e.message;
          case ErrorField.password:
          case ErrorField.general:
            _generalError = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModalFrame(
      icon: Icons.person_add_alt_1_rounded,
      title: 'Crear cuenta',
      subtitle:
          'Completa tus datos. Te enviaremos un enlace para verificar tu '
          'correo y luego crearás tu contraseña.',
      onClose: _loading ? () {} : null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RegistrationSteps(current: 0),
            const SizedBox(height: 20),
            if (_generalError != null) ...[
              StatusBanner(message: _generalError!, type: StatusType.error),
              const SizedBox(height: 16),
            ],
            LayoutBuilder(
              builder: (context, c) {
                final nombre = CustomTextField(
                  fieldKey: const Key('register_nombre'),
                  label: 'Nombre',
                  hint: 'Ej.: María José',
                  icon: Icons.badge_outlined,
                  controller: _nombreCtrl,
                  validator: Validators.firstName,
                  maxLength: AppConstants.maxNameLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  enabled: !_loading,
                  autofocus: true,
                );
                final apellido = CustomTextField(
                  fieldKey: const Key('register_apellido'),
                  label: 'Apellido',
                  hint: 'Ej.: Pérez de la Cruz',
                  icon: Icons.badge_outlined,
                  controller: _apellidoCtrl,
                  validator: Validators.lastName,
                  maxLength: AppConstants.maxNameLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                  enabled: !_loading,
                );
                if (c.maxWidth < 420) {
                  return Column(
                    children: [nombre, const SizedBox(height: 16), apellido],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: nombre),
                    const SizedBox(width: 12),
                    Expanded(child: apellido),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              fieldKey: const Key('register_dni'),
              label: 'DNI',
              hint: '8 dígitos',
              icon: Icons.credit_card_outlined,
              controller: _dniCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(AppConstants.dniLength),
              ],
              validator: Validators.dni,
              errorText: _dniError,
              onChanged: (_) {
                if (_dniError != null) setState(() => _dniError = null);
              },
              enabled: !_loading,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              fieldKey: const Key('register_fecha'),
              label: 'Fecha de nacimiento',
              hint: 'dd/mm/aaaa',
              icon: Icons.calendar_today_outlined,
              controller: _fechaCtrl,
              readOnly: true,
              onTap: _pickDate,
              validator: (_) => Validators.birthDate(_fechaNacimiento),
              suffix: IconButton(
                tooltip: 'Elegir fecha',
                icon: const Icon(Icons.edit_calendar_outlined, size: 20),
                onPressed: _pickDate,
              ),
              enabled: !_loading,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              fieldKey: const Key('register_correo'),
              label: 'Correo electrónico',
              hint: 'nombre@correo.com',
              icon: Icons.mail_outline_rounded,
              controller: _correoCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              errorText: _emailError,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              onSubmitted: (_) => _submit(),
              enabled: !_loading,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              key: const Key('register_submit'),
              label: 'Continuar',
              icon: Icons.arrow_forward_rounded,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.of(context).maybePop(),
                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
