import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_exception.dart';
import '../../core/validators/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_banner.dart';

/// Paso 3 del registro: crear la contraseña definitiva.
///
/// Solo se abre cuando Firebase ya confirmó la verificación del correo, y el
/// proveedor lo vuelve a comprobar antes de guardar la contraseña. La
/// contraseña no se almacena en ningún lugar de la aplicación.
class CreatePasswordModal extends StatefulWidget {
  const CreatePasswordModal({super.key, this.policy = PasswordPolicy.standard});

  final PasswordPolicy policy;

  @override
  State<CreatePasswordModal> createState() => _CreatePasswordModalState();
}

class _CreatePasswordModalState extends State<CreatePasswordModal> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().completeRegistration(
        _passwordCtrl.text,
      );
      // Al terminar, la app vuelve al login y cierra este modal.
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordCtrl.text;
    final requirements = widget.policy.evaluate(password);
    final strength = widget.policy.strength(password);

    return AppModalFrame(
      icon: Icons.lock_outline_rounded,
      title: 'Crea tu contraseña',
      subtitle: 'Tu correo está verificado. Elige una contraseña segura.',
      iconColor: AppColors.violet,
      onClose: _loading ? () {} : null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              StatusBanner(message: _error!, type: StatusType.error),
              const SizedBox(height: 16),
            ],
            CustomTextField(
              fieldKey: const Key('create_password'),
              label: 'Nueva contraseña',
              hint: 'Mínimo ${widget.policy.minLength} caracteres',
              icon: Icons.lock_outline_rounded,
              controller: _passwordCtrl,
              obscure: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) => Validators.password(v, policy: widget.policy),
              onChanged: (_) => setState(() {}),
              enabled: !_loading,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            _StrengthBar(strength: strength),
            const SizedBox(height: 12),
            for (final r in requirements) _RequirementRow(requirement: r),
            const SizedBox(height: 16),
            CustomTextField(
              fieldKey: const Key('create_password_confirm'),
              label: 'Confirmar contraseña',
              hint: 'Repite la contraseña',
              icon: Icons.lock_outline_rounded,
              controller: _confirmCtrl,
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) =>
                  Validators.confirmPassword(v, _passwordCtrl.text),
              onSubmitted: (_) => _submit(),
              enabled: !_loading,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              key: const Key('create_password_submit'),
              label: 'Crear contraseña',
              icon: Icons.check_rounded,
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (double value, Color color, String label) = switch (strength) {
      PasswordStrength.empty => (0, palette.border, 'Sin contraseña'),
      PasswordStrength.weak => (0.33, AppColors.error, 'Débil'),
      PasswordStrength.medium => (0.66, palette.warning, 'Aceptable'),
      PasswordStrength.strong => (1, palette.success, 'Fuerte'),
    };
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: value),
              duration: const Duration(milliseconds: 250),
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                color: color,
                backgroundColor: palette.border,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 92,
          child: Text(
            'Seguridad: $label',
            style: TextStyle(
              fontSize: 12,
              color: color == palette.border ? palette.textSecondary : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.requirement});

  final PasswordRequirement requirement;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = requirement.met ? palette.success : palette.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              requirement.met
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              key: ValueKey(requirement.met),
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              requirement.label,
              style: TextStyle(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
