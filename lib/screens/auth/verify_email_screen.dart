import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_exception.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/registration_steps.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/status_banner.dart';
import 'create_password_modal.dart';

/// Pasos 2 y 3 del registro.
///
/// Se muestra mientras la cuenta está pendiente: primero espera a que Firebase
/// confirme la verificación del correo y después permite crear la contraseña.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _ticker;
  bool _checking = false;
  bool _resending = false;
  bool _cancelling = false;
  String? _message;
  StatusType _messageType = StatusType.info;
  bool _autoOpened = false;
  int _shownCooldown = 0;

  @override
  void initState() {
    super.initState();
    // Refresca la cuenta regresiva del reenvío solo cuando cambia.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = context.read<AuthProvider>().resendCooldown;
      if (left != _shownCooldown) setState(() => _shownCooldown = left);
    });
    final auth = context.read<AuthProvider>();
    if (auth.verificationSendFailed) {
      _message =
          'Creamos tu cuenta, pero no pudimos enviar el correo. Pulsa '
          '«Reenviar correo».';
      _messageType = StatusType.warning;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenPassword());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _busy => _checking || _resending || _cancelling;

  void _maybeOpenPassword() {
    if (!mounted || _autoOpened) return;
    if (context.read<AuthProvider>().status == AuthStatus.pendingPassword) {
      _autoOpened = true;
      _openCreatePassword();
    }
  }

  void _openCreatePassword() {
    showAppModal<void>(
      context: context,
      builder: (_) => const CreatePasswordModal(),
    );
  }

  Future<void> _check() async {
    if (_busy) return;
    setState(() {
      _checking = true;
      _message = null;
    });
    try {
      final verified = await context.read<AuthProvider>().checkEmailVerified();
      if (!mounted) return;
      if (verified) {
        setState(() {
          _message = '¡Correo verificado! Ahora crea tu contraseña.';
          _messageType = StatusType.success;
        });
        _maybeOpenPassword();
      } else {
        setState(() {
          _message =
              'Aún no detectamos la verificación. Abre el enlace del correo y '
              'vuelve a intentarlo.';
          _messageType = StatusType.warning;
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
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    if (_busy) return;
    setState(() {
      _resending = true;
      _message = null;
    });
    try {
      await context.read<AuthProvider>().resendVerification();
      if (mounted) {
        setState(() {
          _message = 'Te enviamos un nuevo enlace de verificación.';
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
      if (mounted) setState(() => _resending = false);
    }
  }

  /// Alternativa si la página del enlace muestra un error: pegar el enlace.
  Future<void> _pasteLink() async {
    if (_busy) return;
    final link = await showDialog<String>(
      context: context,
      builder: (_) => const _PasteLinkDialog(),
    );
    if (link == null || link.trim().isEmpty || !mounted) return;
    setState(() {
      _checking = true;
      _message = null;
    });
    try {
      final verified = await context.read<AuthProvider>().verifyWithLink(link);
      if (!mounted) return;
      if (verified) {
        setState(() {
          _message = '¡Correo verificado! Ahora crea tu contraseña.';
          _messageType = StatusType.success;
        });
        _maybeOpenPassword();
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message;
          _messageType = StatusType.error;
        });
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _cancel() async {
    if (_busy) return;
    final ok = await showConfirmDialog(
      context: context,
      title: 'Cancelar registro',
      message:
          'Se eliminarán los datos de este registro incompleto y podrás '
          'empezar de nuevo. ¿Deseas continuar?',
      confirmLabel: 'Cancelar registro',
      cancelLabel: 'Seguir aquí',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await context.read<AuthProvider>().cancelRegistration();
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message;
          _messageType = StatusType.error;
        });
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final verified = auth.status == AuthStatus.pendingPassword;
    final theme = Theme.of(context);
    final isMobile = Breakpoints.isMobile(context);
    final cooldown = auth.resendCooldown;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: AppLogo(size: 36)),
        const SizedBox(height: 24),
        RegistrationSteps(current: verified ? 2 : 1),
        const SizedBox(height: 28),
        Center(child: _EnvelopeIllustration(verified: verified)),
        const SizedBox(height: 24),
        Text(
          verified ? 'Correo verificado' : 'Verifica tu correo electrónico',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            text: verified
                ? 'Confirmamos la dirección '
                : 'Enviamos un enlace de verificación a ',
            children: [
              TextSpan(
                text: auth.pendingEmail ?? '',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: verified
                    ? '. Ya puedes crear tu contraseña.'
                    : '. Ábrelo y pulsa el enlace; luego vuelve aquí.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        if (!verified) ...[
          const SizedBox(height: 8),
          Text(
            'Si no lo ves en unos minutos, revisa la carpeta de spam.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _message == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: StatusBanner(message: _message!, type: _messageType),
                ),
        ),
        if (verified)
          PrimaryButton(
            key: const Key('verify_create_password'),
            label: 'Crear contraseña',
            icon: Icons.lock_outline_rounded,
            onPressed: _busy ? null : _openCreatePassword,
          )
        else ...[
          PrimaryButton(
            key: const Key('verify_check'),
            label: 'Ya verifiqué mi correo',
            icon: Icons.verified_outlined,
            loading: _checking,
            onPressed: _busy ? null : _check,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            key: const Key('verify_resend'),
            label: cooldown > 0
                ? 'Reenviar correo en ${cooldown}s'
                : 'Reenviar correo',
            icon: Icons.refresh_rounded,
            loading: _resending,
            onPressed: _busy || cooldown > 0 ? null : _resend,
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              key: const Key('verify_paste_link'),
              onPressed: _busy ? null : _pasteLink,
              child: const Text('¿El enlace muestra un error? Pégalo aquí'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            key: const Key('verify_cancel'),
            onPressed: _busy ? null : _cancel,
            icon: _cancelling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Cancelar registro y volver al inicio'),
          ),
        ),
      ],
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
              constraints: const BoxConstraints(maxWidth: 480),
              child: isMobile
                  ? content
                  : Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
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

class _PasteLinkDialog extends StatefulWidget {
  const _PasteLinkDialog();

  @override
  State<_PasteLinkDialog> createState() => _PasteLinkDialogState();
}

class _PasteLinkDialogState extends State<_PasteLinkDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pegar enlace de verificación'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'En el correo, copia la dirección del enlace (clic derecho → '
              '«Copiar dirección del enlace») y pégala aquí.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('paste_link_field'),
              controller: _ctrl,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'https://…/__/auth/action?mode=verifyEmail&oobCode=…',
              ),
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          child: const Text('Verificar'),
        ),
      ],
    );
  }
}

/// Ilustración de un sobre creada con widgets.
class _EnvelopeIllustration extends StatelessWidget {
  const _EnvelopeIllustration({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 120,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mail_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: a, child: child),
                child: Container(
                  key: ValueKey(verified),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: verified
                        ? context.palette.success
                        : context.palette.warning,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    verified ? Icons.check_rounded : Icons.schedule_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
