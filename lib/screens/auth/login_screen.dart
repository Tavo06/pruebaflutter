import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_exception.dart';
import '../../core/validators/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/status_banner.dart';
import 'forgot_password_modal.dart';
import 'register_modal.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _googleBusy = false;
  FlashMessage? _message;

  bool get _busy => _loading || _googleBusy;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _message = auth.takeFlash();
    _emailCtrl.text = auth.lastEmail ?? '';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _message = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.signIn(
        email: Validators.normalizeEmail(_emailCtrl.text),
        password: _passwordCtrl.text,
      );
      // Si la cuenta no tiene perfil, el proveedor deja un aviso.
      final flash = auth.takeFlash();
      if (flash != null && mounted) setState(() => _message = flash);
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _message = FlashMessage(e.message, FlashType.error));
      }
    } finally {
      if (mounted) {
        _passwordCtrl.clear();
        setState(() => _loading = false);
      }
    }
  }

  void _onGoogleBusy(bool busy) {
    setState(() {
      _googleBusy = busy;
      if (busy) _message = null;
    });
    if (!busy && mounted) {
      // Avisos del proveedor (p. ej. correo de Google sin verificar).
      final flash = context.read<AuthProvider>().takeFlash();
      if (flash != null) setState(() => _message = flash);
    }
  }

  void _openRegister() {
    showAppModal<void>(context: context, builder: (_) => const RegisterModal());
  }

  void _openForgot() {
    showAppModal<void>(
      context: context,
      builder: (_) =>
          ForgotPasswordModal(initialEmail: _emailCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= Breakpoints.desktop;
          final form = _buildForm(context, showLogo: !wide);
          if (!wide) {
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Breakpoints.formMaxWidth,
                    ),
                    child: constraints.maxWidth >= Breakpoints.tablet
                        ? _FormCard(child: form)
                        : form,
                  ),
                ),
              ),
            );
          }
          return Row(
            children: [
              const Expanded(flex: 10, child: _BrandPanel()),
              Expanded(
                flex: 11,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: Breakpoints.formMaxWidth,
                        ),
                        child: form,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool showLogo}) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final message = _message;

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLogo) ...[
              const Center(child: AppLogo(size: 40)),
              const SizedBox(height: 32),
            ],
            Text('Iniciar sesión', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Bienvenido de nuevo. Ingresa tus datos para continuar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: message == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: StatusBanner(
                        message: message.text,
                        type: switch (message.type) {
                          FlashType.success => StatusType.success,
                          FlashType.info => StatusType.info,
                          FlashType.error => StatusType.error,
                        },
                      ),
                    ),
            ),
            GoogleSignInButton(
              enabled: !_loading,
              onBusyChanged: _onGoogleBusy,
              onError: (m) => setState(
                () => _message = FlashMessage(m, FlashType.error),
              ),
            ),
            const SizedBox(height: 20),
            const LabeledDivider(text: 'o continúa con tu correo'),
            const SizedBox(height: 20),
            CustomTextField(
              fieldKey: const Key('login_email'),
              label: 'Correo electrónico',
              hint: 'nombre@correo.com',
              icon: Icons.mail_outline_rounded,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              enabled: !_busy,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              fieldKey: const Key('login_password'),
              label: 'Contraseña',
              hint: 'Tu contraseña',
              icon: Icons.lock_outline_rounded,
              controller: _passwordCtrl,
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: Validators.loginPassword,
              onSubmitted: (_) => _submit(),
              enabled: !_busy,
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                // Solo en web se puede elegir si la sesión sobrevive al cierre
                // del navegador. En Android y Windows siempre persiste.
                if (kIsWeb)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _busy
                        ? null
                        : () => auth.rememberSession = !auth.rememberSession,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: auth.rememberSession,
                          onChanged: _busy
                              ? null
                              : (v) => auth.rememberSession = v ?? true,
                        ),
                        const Text('Mantener sesión iniciada'),
                        const SizedBox(width: 8),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
                TextButton(
                  onPressed: _busy ? null : _openForgot,
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              key: const Key('login_submit'),
              label: 'Iniciar sesión',
              icon: Icons.login_rounded,
              loading: _loading,
              onPressed: _googleBusy ? null : _submit,
            ),
            const SizedBox(height: 24),
            LabeledDivider(text: '¿Aún no tienes cuenta?'),
            const SizedBox(height: 16),
            SecondaryButton(
              key: const Key('login_register'),
              label: 'Crear cuenta',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: _busy ? null : _openRegister,
            ),
            const SizedBox(height: 28),
            Text(
              'Tus datos se utilizan únicamente para gestionar tu cuenta en '
              '${AppConstants.appName}. Nunca te pediremos tu contraseña por '
              'correo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.palette.border),
        boxShadow: AppShadows.soft(context),
      ),
      child: child,
    );
  }
}

/// Panel de bienvenida (escritorio): verde oliva oscuro, sin imágenes.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = palette.onSidebar;

    return ColoredBox(
      color: palette.sidebar,
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -120,
            child: _Ring(size: 380, color: fg.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: -160,
            left: -110,
            child: _Ring(size: 420, color: fg.withValues(alpha: 0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLogo(size: 40, inverted: true, nameColor: fg),
                const Spacer(),
                Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Te damos la\nbienvenida.',
                  style: TextStyle(
                    color: fg,
                    fontSize: 40,
                    height: 1.12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Text(
                    AppConstants.appTagline,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.72),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '© ${DateTime.now().year} ${AppConstants.appName}',
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.2),
        color: color.withValues(alpha: color.a * 0.6),
      ),
    );
  }
}
