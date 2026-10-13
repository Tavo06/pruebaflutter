import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_exception.dart';
import '../../core/validators/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_text_field.dart';
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
  FlashMessage? _message;

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
    if (_loading) return;
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
              const Expanded(flex: 11, child: _BrandPanel()),
              Expanded(
                flex: 10,
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
              const Center(child: AppLogo(size: 44)),
              const SizedBox(height: 28),
            ],
            Text('Iniciar sesión', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Bienvenido de nuevo. Ingresa tus datos para continuar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
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
              enabled: !_loading,
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
              enabled: !_loading,
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
                    onTap: _loading
                        ? null
                        : () => auth.rememberSession = !auth.rememberSession,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: auth.rememberSession,
                          onChanged: _loading
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
                  onPressed: _loading ? null : _openForgot,
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
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '¿Aún no tienes cuenta?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            SecondaryButton(
              key: const Key('login_register'),
              label: 'Crear cuenta',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: _loading ? null : _openRegister,
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
        boxShadow: AppShadows.soft(context),
      ),
      child: child,
    );
  }
}

/// Panel ilustrativo de la izquierda en pantallas grandes, dibujado con
/// Flutter (sin imágenes externas).
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, Color(0xFF2A2F8F), AppColors.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _Circle(size: 340, opacity: 0.08),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _Circle(size: 380, opacity: 0.06),
          ),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(size: 44, nameColor: Colors.white),
                const Spacer(),
                const _PreviewCard(),
                const SizedBox(height: 40),
                const Text(
                  'Organiza tu trabajo\ncon fluidez.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '© ${DateTime.now().year} ${AppConstants.appName}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
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

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity * 2),
          width: 1.5,
        ),
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

/// Tarjeta decorativa que sugiere un panel de trabajo.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double alpha) => Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bar(120, 0.55), const SizedBox(height: 6), bar(80, 0.3)],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final h in [0.35, 0.55, 0.45, 0.8, 0.6, 0.95, 0.7])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FractionallySizedBox(
                          heightFactor: h,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
