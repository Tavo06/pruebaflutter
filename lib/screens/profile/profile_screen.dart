import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../widgets/responsive_layout.dart';
import '../home/home_screen.dart';

/// Resumen del perfil del usuario autenticado.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = Breakpoints.isMobile(context);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final palette = context.palette;

    return SingleChildScrollView(
      padding: EdgeInsets.all(mobile ? 16 : 28),
      child: MaxWidthBox(
        maxWidth: 820,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Flex(
                  direction: mobile ? Axis.vertical : Axis.horizontal,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar(profile: profile, size: 76),
                    SizedBox(width: mobile ? 0 : 20, height: mobile ? 16 : 0),
                    _flexibleIf(
                      !mobile,
                      Column(
                        crossAxisAlignment: mobile
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.nombreCompleto,
                            textAlign: mobile
                                ? TextAlign.center
                                : TextAlign.start,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.correo,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: palette.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: palette.success,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Correo verificado',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.credit_card_outlined,
                      label: 'DNI',
                      value: profile.dni == null ? '—' : _maskDni(profile.dni!),
                    ),
                    const Divider(height: 1, indent: 64),
                    _InfoTile(
                      icon: Icons.cake_outlined,
                      label: 'Fecha de nacimiento',
                      value: profile.fechaNacimiento == null
                          ? '—'
                          : dateFmt.format(profile.fechaNacimiento!),
                    ),
                    const Divider(height: 1, indent: 64),
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Número de teléfono',
                      value: profile.telefono ?? 'Sin registrar',
                      action: profile.tieneTelefono
                          ? null
                          : TextButton(
                              onPressed: () =>
                                  HomeScreen.irA(context, HomeSection.datos),
                              child: const Text('Añadir'),
                            ),
                    ),
                    const Divider(height: 1, indent: 64),
                    _InfoTile(
                      icon: Icons.event_available_outlined,
                      label: 'Miembro desde',
                      value: profile.createdAt != null
                          ? dateFmt.format(profile.createdAt!)
                          : '—',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _flexibleIf(bool condition, Widget child) =>
      condition ? Expanded(child: child) : child;

  /// Muestra solo los últimos dígitos del DNI.
  static String _maskDni(String dni) =>
      dni.length <= 3 ? dni : '•••••${dni.substring(dni.length - 3)}';
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.action,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: context.palette.textSecondary),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: action,
    );
  }
}
