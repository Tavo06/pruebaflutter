import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_exception.dart';
import '../../core/validators/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/status_banner.dart';

/// Envía el enlace de restablecimiento de Firebase.
///
/// El mensaje de confirmación es el mismo exista o no la cuenta, para no
/// revelar qué correos están registrados.
class ForgotPasswordModal extends StatefulWidget {
  const ForgotPasswordModal({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordModal> createState() => _ForgotPasswordModalState();
}

class _ForgotPasswordModalState extends State<ForgotPasswordModal> {
  final _formKey = GlobalKey<FormState>();
  late final _emailCtrl = TextEditingController(text: widget.initialEmail);
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().sendPasswordReset(
        Validators.normalizeEmail(_emailCtrl.text),
      );
      if (mounted) setState(() => _sent = true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModalFrame(
      icon: Icons.lock_reset_rounded,
      title: 'Recuperar contraseña',
      subtitle:
          'Escribe tu correo y te enviaremos un enlace para crear una nueva '
          'contraseña.',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _sent ? _buildSent(context) : _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            StatusBanner(message: _error!, type: StatusType.error),
            const SizedBox(height: 16),
          ],
          CustomTextField(
            fieldKey: const Key('forgot_email'),
            label: 'Correo electrónico',
            hint: 'nombre@correo.com',
            icon: Icons.mail_outline_rounded,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
            enabled: !_loading,
            autofocus: widget.initialEmail.isEmpty,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            key: const Key('forgot_submit'),
            label: 'Enviar enlace',
            icon: Icons.send_rounded,
            loading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Volver al inicio de sesión',
            onPressed: _loading ? null : () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSent(BuildContext context) {
    return Column(
      key: const ValueKey('sent'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StatusBanner(
          message:
              'Si existe una cuenta asociada a ese correo, recibirás un enlace '
              'para restablecer tu contraseña en unos minutos. Revisa también '
              'la carpeta de spam.',
          type: StatusType.success,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Volver al inicio de sesión',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
