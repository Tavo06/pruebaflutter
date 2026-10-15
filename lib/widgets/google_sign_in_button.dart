import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_exception.dart';
import '../providers/auth_provider.dart';

/// Botón «Continuar con Google».
///
/// Lo usan el login y el modal de registro; ambos llaman al mismo
/// `AuthProvider.signInWithGoogle`, así que el comportamiento es idéntico.
/// La cancelación del selector no se muestra como error.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onError,
    this.onBusyChanged,
    this.enabled = true,
  });

  /// Recibe el mensaje de error listo para mostrar.
  final ValueChanged<String> onError;

  /// Avisa cuando empieza y termina el acceso, para bloquear el formulario.
  final ValueChanged<bool>? onBusyChanged;
  final bool enabled;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _busy = false;

  void _setBusy(bool value) {
    setState(() => _busy = value);
    widget.onBusyChanged?.call(value);
  }

  Future<void> _run() async {
    if (_busy || !widget.enabled) return;
    _setBusy(true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
      // Si el acceso prospera, la app cambia de pantalla por sí sola.
    } on AppException catch (e) {
      if (!e.isCancellation && mounted) widget.onError(e.message);
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final outside = _busy && auth.googleRunsOutsideApp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: _busy
              ? 'Continuar con Google, procesando'
              : 'Continuar con Google',
          excludeSemantics: true,
          child: OutlinedButton(
            key: const Key('google_sign_in'),
            onPressed: widget.enabled && !_busy ? _run : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _busy
                      ? const SizedBox(
                          key: ValueKey('busy'),
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const GoogleLogo(key: ValueKey('logo'), size: 18),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    'Continuar con Google',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: outside
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Completa el acceso en tu navegador.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton(
                        key: const Key('google_cancel'),
                        onPressed: auth.cancelGoogleSignIn,
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Separador horizontal con un texto centrado.
class LabeledDivider extends StatelessWidget {
  const LabeledDivider({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Flexible(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.palette.textSecondary),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Logotipo «G» de Google dibujado con Flutter (sin imágenes externas).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.width - stroke) / 2,
    );
    double rad(double deg) => deg * math.pi / 180;
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Ángulos en grados, 0° a las 3 en punto y sentido horario.
    canvas.drawArc(rect, rad(-145), rad(100), false, arc(AppColors.googleRed));
    canvas.drawArc(rect, rad(145), rad(70), false, arc(AppColors.googleYellow));
    canvas.drawArc(rect, rad(40), rad(105), false, arc(AppColors.googleGreen));
    canvas.drawArc(rect, rad(0), rad(42), false, arc(AppColors.googleBlue));
    canvas.drawRect(
      Rect.fromLTRB(
        size.width / 2,
        size.height / 2 - stroke / 2,
        size.width,
        size.height / 2 + stroke / 2,
      ),
      Paint()..color = AppColors.googleBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
