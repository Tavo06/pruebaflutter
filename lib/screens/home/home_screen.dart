import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/responsive_layout.dart';
import '../profile/my_data_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import 'exercise_module.dart';

/// Secciones de la navegación principal.
///
/// Para añadir una sección permanente, agrega un valor aquí y su vista en
/// [_HomeScreenState._buildSection]. El orden es el orden del menú.
enum HomeSection {
  inicio('Inicio', Icons.space_dashboard_outlined, Icons.space_dashboard),
  perfil(
    'Mi perfil',
    Icons.person_outline_rounded,
    Icons.person_rounded,
    shortLabel: 'Perfil',
  ),
  datos(
    'Mis datos',
    Icons.badge_outlined,
    Icons.badge_rounded,
    shortLabel: 'Datos',
  ),
  configuracion(
    'Configuración',
    Icons.settings_outlined,
    Icons.settings,
    shortLabel: 'Ajustes',
  );

  const HomeSection(
    this.label,
    this.icon,
    this.selectedIcon, {
    this.shortLabel,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Texto más corto para la barra inferior del móvil.
  final String? shortLabel;

  /// Secciones de la barra inferior del móvil (caben bien hasta 5). Si añades
  /// más, filtra aquí las que solo deban abrirse desde el menú de usuario.
  static List<HomeSection> get bottomBar => values;
}

/// Estructura permanente del área privada: navegación, barra superior y
/// contenedor de la sección activa. Solo se construye con sesión completa.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Cambia de sección desde cualquier vista hija, por ejemplo:
  ///   HomeScreen.irA(context, HomeSection.datos);
  static void irA(BuildContext context, HomeSection section) =>
      context.findAncestorStateOfType<_HomeScreenState>()?._select(section);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeSection _section = HomeSection.inicio;

  void _select(HomeSection s) => setState(() => _section = s);

  Future<void> _signOut() => context.read<AuthProvider>().signOut();

  Widget _buildSection(UserProfile profile) {
    switch (_section) {
      case HomeSection.inicio:
        return _DashboardView(profile: profile);
      case HomeSection.perfil:
        return ProfileScreen(profile: profile);
      case HomeSection.datos:
        return MyDataScreen(profile: profile);
      case HomeSection.configuracion:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    // Protección adicional: sin perfil no se muestra contenido privado.
    if (profile == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = screenSizeForWidth(constraints.maxWidth);
        final body = _MainArea(
          title: _section.label,
          profile: profile,
          compactUser: size == ScreenSize.mobile,
          onSelect: _select,
          onSignOut: _signOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            child: KeyedSubtree(
              key: ValueKey(_section),
              child: _buildSection(profile),
            ),
          ),
        );

        if (size == ScreenSize.mobile) {
          final items = HomeSection.bottomBar;
          final index = items.contains(_section)
              ? items.indexOf(_section)
              : items.indexOf(HomeSection.perfil);
          return Scaffold(
            body: body,
            bottomNavigationBar: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.palette.border)),
              ),
              child: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) => _select(items[i]),
                destinations: [
                  for (final s in items)
                    NavigationDestination(
                      icon: Icon(s.icon),
                      selectedIcon: Icon(s.selectedIcon),
                      label: s.shortLabel ?? s.label,
                    ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              _Sidebar(
                expanded: size == ScreenSize.desktop,
                selected: _section,
                onSelect: _select,
                onSignOut: _signOut,
              ),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Barra lateral
// -----------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.expanded,
    required this.selected,
    required this.onSelect,
    required this.onSignOut,
  });

  final bool expanded;
  final HomeSection selected;
  final ValueChanged<HomeSection> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = palette.onSidebar;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: expanded ? 248 : 80,
      color: palette.sidebar,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 16 : 12,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(left: expanded ? 8 : 0, bottom: 32),
                child: Align(
                  alignment: expanded ? Alignment.centerLeft : Alignment.center,
                  child: AppLogo(
                    size: 36,
                    showName: expanded,
                    inverted: true,
                    nameColor: fg,
                  ),
                ),
              ),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Text(
                    'MENÚ',
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.45),
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              for (final s in HomeSection.values)
                _SidebarItem(
                  icon: selected == s ? s.selectedIcon : s.icon,
                  label: s.label,
                  selected: selected == s,
                  expanded: expanded,
                  onTap: () => onSelect(s),
                ),
              const Spacer(),
              Divider(color: fg.withValues(alpha: 0.12)),
              const SizedBox(height: 8),
              _SidebarItem(
                key: const Key('sidebar_logout'),
                icon: Icons.logout_rounded,
                label: 'Cerrar sesión',
                selected: false,
                expanded: expanded,
                onTap: onSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final base = palette.onSidebar;
    final fg = selected ? base : base.withValues(alpha: 0.68);
    final item = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          hoverColor: base.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
            decoration: BoxDecoration(
              color: selected ? base.withValues(alpha: 0.12) : null,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                if (expanded)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 3,
                    height: selected ? 18 : 0,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Icon(icon, color: fg, size: 21),
                if (expanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: expanded ? item : Tooltip(message: label, child: item),
    );
  }
}

// -----------------------------------------------------------------------------
// Área principal con barra superior
// -----------------------------------------------------------------------------

enum _UserMenuAction { perfil, datos, configuracion, salir }

class _MainArea extends StatelessWidget {
  const _MainArea({
    required this.title,
    required this.profile,
    required this.compactUser,
    required this.onSelect,
    required this.onSignOut,
    required this.child,
  });

  final String title;
  final UserProfile profile;
  final bool compactUser;
  final ValueChanged<HomeSection> onSelect;
  final VoidCallback onSignOut;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: compactUser ? 16 : 28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: context.palette.border),
              ),
            ),
            child: Row(
              children: [
                if (compactUser) ...[
                  const AppLogo(size: 30, showName: false),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const _ThemeToggle(),
                const SizedBox(width: 4),
                PopupMenuButton<_UserMenuAction>(
                  key: const Key('user_menu'),
                  tooltip: 'Menú de usuario',
                  position: PopupMenuPosition.under,
                  onSelected: (a) {
                    switch (a) {
                      case _UserMenuAction.perfil:
                        onSelect(HomeSection.perfil);
                      case _UserMenuAction.datos:
                        onSelect(HomeSection.datos);
                      case _UserMenuAction.configuracion:
                        onSelect(HomeSection.configuracion);
                      case _UserMenuAction.salir:
                        onSignOut();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _UserMenuAction.perfil,
                      child: ListTile(
                        leading: Icon(Icons.person_outline_rounded),
                        title: Text('Mi perfil'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: _UserMenuAction.datos,
                      child: ListTile(
                        leading: Icon(Icons.badge_outlined),
                        title: Text('Mis datos'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: _UserMenuAction.configuracion,
                      child: ListTile(
                        leading: Icon(Icons.settings_outlined),
                        title: Text('Configuración'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      key: const Key('menu_logout'),
                      value: _UserMenuAction.salir,
                      child: ListTile(
                        leading: Icon(Icons.logout_rounded, color: error),
                        title: Text(
                          'Cerrar sesión',
                          style: TextStyle(color: error),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UserAvatar(profile: profile, size: 36),
                        if (!compactUser) ...[
                          const SizedBox(width: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.nombreCompleto,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  profile.correo,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        Icon(
                          Icons.expand_more_rounded,
                          color: context.palette.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Alterna entre tema claro y oscuro desde la barra superior.
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      key: const Key('theme_toggle'),
      tooltip: dark ? 'Usar tema claro' : 'Usar tema oscuro',
      onPressed: () =>
          themeProvider.setMode(dark ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}

/// Avatar con las iniciales del usuario.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.profile, this.size = 40});

  final UserProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        profile.iniciales,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Sección «Inicio»: bienvenida + espacio del ejercicio
// -----------------------------------------------------------------------------

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(mobile ? 16 : 32),
      child: MaxWidthBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WelcomeHeader(name: profile.primerNombre),
            if (!profile.tieneTelefono) ...[
              const SizedBox(height: 20),
              _MissingPhoneNotice(
                onTap: () => HomeScreen.irA(context, HomeSection.datos),
              ),
            ],
            SizedBox(height: mobile ? 20 : 28),
            // Contenido reemplazable: ver lib/screens/home/exercise_module.dart.
            const ExerciseModule(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 3,
          decoration: BoxDecoration(
            color: context.palette.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 14),
        Text('¡Hola, $name!', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Bienvenido a tu espacio de trabajo.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Aviso discreto para perfiles antiguos que aún no tienen teléfono.
class _MissingPhoneNotice extends StatelessWidget {
  const _MissingPhoneNotice({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: palette.subtleFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.phone_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Añade tu número de teléfono para completar tu perfil.'),
          ),
          TextButton(
            key: const Key('add_phone'),
            onPressed: onTap,
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }
}
