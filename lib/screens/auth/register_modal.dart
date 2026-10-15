import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_exception.dart';
import '../../core/validators/validators.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/personal_data_fields.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/registration_steps.dart';
import '../../widgets/status_banner.dart';

/// Paso 1 del registro: datos personales y correo (o alta con Google).
///
/// Al pulsar «Continuar» se crea la cuenta pendiente y se envía el enlace de
/// verificación. El modal se cierra automáticamente cuando la aplicación pasa
/// a la pantalla de verificación (o a «completa tu perfil» con Google).
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
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();

  DateTime? _fechaNacimiento;
  bool _loading = false;
  bool _googleBusy = false;
  String? _emailError;
  String? _dniError;
  String? _generalError;

  bool get _busy => _loading || _googleBusy;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _dniCtrl.dispose();
    _fechaCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _emailError = null;
      _dniError = null;
      _generalError = null;
    });
    // Se validan de nuevo todos los campos (incluido el teléfono) al enviar.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = RegistrationData(
      nombre: Validators.normalizeName(_nombreCtrl.text),
      apellido: Validators.normalizeName(_apellidoCtrl.text),
      dni: _dniCtrl.text.trim(),
      fechaNacimiento: _fechaNacimiento!,
      telefono: _telefonoCtrl.text,
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
          case ErrorField.phone:
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
      icon: Icons.person_add_alt_1_outlined,
      title: 'Crear cuenta',
      subtitle:
          'Completa tus datos. Te enviaremos un enlace para verificar tu '
          'correo y luego crearás tu contraseña.',
      onClose: _busy ? () {} : null,
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
            GoogleSignInButton(
              enabled: !_loading,
              onBusyChanged: (b) => setState(() => _googleBusy = b),
              onError: (m) => setState(() => _generalError = m),
            ),
            const SizedBox(height: 20),
            const LabeledDivider(text: 'o continúa con tu correo'),
            const SizedBox(height: 20),
            NameFields(
              nombre: _nombreCtrl,
              apellido: _apellidoCtrl,
              enabled: !_busy,
            ),
            const SizedBox(height: 16),
            DniField(
              controller: _dniCtrl,
              errorText: _dniError,
              onChanged: (_) {
                if (_dniError != null) setState(() => _dniError = null);
              },
              enabled: !_busy,
            ),
            const SizedBox(height: 16),
            BirthDateField(
              controller: _fechaCtrl,
              value: _fechaNacimiento,
              onPicked: (d) {
                setState(() => _fechaNacimiento = d);
                _formKey.currentState?.validate();
              },
              enabled: !_busy,
            ),
            const SizedBox(height: 16),
            PhoneField(controller: _telefonoCtrl, enabled: !_busy),
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
              enabled: !_busy,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              key: const Key('register_submit'),
              label: 'Continuar',
              icon: Icons.arrow_forward_rounded,
              loading: _loading,
              onPressed: _googleBusy ? null : _submit,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _busy
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
