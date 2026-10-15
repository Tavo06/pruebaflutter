import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_exception.dart';
import '../../core/validators/validators.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/personal_data_fields.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_banner.dart';

/// Perfil pendiente de una cuenta de Google.
///
/// Google solo aporta el nombre y el correo; DNI, fecha de nacimiento y
/// teléfono los introduce el usuario. Hasta guardarlos no se accede al
/// dashboard (el estado lo decide `AuthProvider`, no esta pantalla).
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final UserProfile? _initial = context.read<AuthProvider>().profile;
  late final _nombreCtrl = TextEditingController(text: _initial?.nombre);
  late final _apellidoCtrl = TextEditingController(text: _initial?.apellido);
  final _dniCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  late final _telefonoCtrl = TextEditingController(text: _initial?.telefono);

  DateTime? _fechaNacimiento;
  bool _saving = false;
  bool _leaving = false;
  String? _dniError;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _dniCtrl.dispose();
    _fechaCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _leaving) return;
    setState(() {
      _error = null;
      _dniError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    try {
      await auth.completePendingProfile(
        RegistrationData(
          nombre: Validators.normalizeName(_nombreCtrl.text),
          apellido: Validators.normalizeName(_apellidoCtrl.text),
          dni: _dniCtrl.text.trim(),
          fechaNacimiento: _fechaNacimiento!,
          telefono: _telefonoCtrl.text,
          correo: auth.profile?.correo ?? '',
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.field == ErrorField.dni) {
          _dniError = e.message;
        } else {
          _error = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    if (_saving || _leaving) return;
    setState(() => _leaving = true);
    await context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Breakpoints.isMobile(context);
    final correo = context.select<AuthProvider, String>(
      (a) => a.profile?.correo ?? '',
    );
    final busy = _saving || _leaving;

    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AppLogo(size: 36)),
          const SizedBox(height: 28),
          Text(
            'Completa tu perfil',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Iniciaste sesión con Google. Para terminar tu registro necesitamos '
            'algunos datos personales.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            StatusBanner(message: _error!, type: StatusType.error),
            const SizedBox(height: 16),
          ],
          CustomTextField(
            label: 'Correo electrónico',
            icon: Icons.mail_outline_rounded,
            initialValue: correo,
            enabled: false,
            suffix: const Icon(Icons.verified_outlined, size: 18),
          ),
          const SizedBox(height: 16),
          NameFields(
            nombre: _nombreCtrl,
            apellido: _apellidoCtrl,
            enabled: !busy,
            keyPrefix: 'profile',
          ),
          const SizedBox(height: 16),
          DniField(
            fieldKey: const Key('profile_dni'),
            controller: _dniCtrl,
            errorText: _dniError,
            onChanged: (_) {
              if (_dniError != null) setState(() => _dniError = null);
            },
            enabled: !busy,
          ),
          const SizedBox(height: 16),
          BirthDateField(
            fieldKey: const Key('profile_fecha'),
            controller: _fechaCtrl,
            value: _fechaNacimiento,
            onPicked: (d) {
              setState(() => _fechaNacimiento = d);
              _formKey.currentState?.validate();
            },
            enabled: !busy,
          ),
          const SizedBox(height: 16),
          PhoneField(
            fieldKey: const Key('profile_telefono'),
            controller: _telefonoCtrl,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            enabled: !busy,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            key: const Key('profile_submit'),
            label: 'Guardar y continuar',
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _leaving ? null : _submit,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              key: const Key('profile_sign_out'),
              onPressed: busy ? null : _signOut,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Cerrar sesión y continuar después'),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 32,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Breakpoints.dialogMaxWidth,
              ),
              child: isMobile
                  ? content
                  : Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: context.palette.border),
                        boxShadow: AppShadows.soft(context),
                      ),
                      child: content,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
