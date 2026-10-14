import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../exercises/finanzas/screens/historial_view.dart';
import '../../exercises/finanzas/screens/nuevo_movimiento_view.dart';
import '../../exercises/finanzas/screens/resumen_view.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
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
  // Secciones del ejercicio de finanzas.
  nuevo(
    'Nuevo movimiento',
    Icons.add_circle_outline_rounded,
    Icons.add_circle_rounded,
    shortLabel: 'Nuevo',
  ),
  historial('Historial', Icons.receipt_long_outlined, Icons.receipt_long),
  resumen('Resumen', Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded),
  // Secciones de la cuenta.
  perfil('Mi perfil', Icons.person_outline_rounded, Icons.person_rounded),
  datos(
    'Mis datos',
    Icons.badge_outlined,
    Icons.badge_rounded,
    inBottomBar: false,
  ),
  configuracion(
    'Configuración',
    Icons.settings_outlined,
    Icons.settings,
    inBottomBar: false,
  );

  const HomeSection(
    this.label,
    this.icon,
    this.selectedIcon, {
    this.shortLabel,
    this.inBottomBar = true,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Texto más corto para la barra inferior del móvil.
  final String? shortLabel;

  /// En móvil caben ~5 secciones abajo; las demás se abren desde el menú de
  /// usuario (avatar, arriba a la derecha).
  final bool inBottomBar;

  static List<HomeSection> get bottomBar =>
      values.where((s) => s.inBottomBar).toList();
}

/// Estructura permanente del área privada: navegación, barra superior y
/// contenedor de la sección activa. Solo se construye con sesión completa.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Cambia de sección desde cualquier vista hija, por ejemplo:
  ///   HomeScreen.irA(context, HomeSection.historial);
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
      case HomeSection.nuevo:
        return const NuevoMovimientoView();
      case HomeSection.historial:
        return const HistorialView();
      case HomeSection.resumen:
        return const ResumenView();
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
          // Las secciones que no están abajo (Mis datos, Configuración)
          // marcan «Mi perfil», que es la sección de la cuenta.
          final index = items.contains(_section)
              ? items.indexOf(_section)
              : items.indexOf(HomeSection.perfil);
          return Scaffold(
            body: body,
            bottomNavigationBar: NavigationBar(
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: expanded ? 252 : 84,
      color: context.palette.sidebar,
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
                padding: EdgeInsets.only(left: expanded ? 8 : 0, bottom: 28),
                child: Align(
                  alignment: expanded ? Alignment.centerLeft : Alignment.center,
                  child: AppLogo(
                    size: 38,
                    showName: expanded,
                    nameColor: Colors.white,
                  ),
                ),
              ),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Text(
                    'MENÚ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
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
              Divider(color: Colors.white.withValues(alpha: 0.1)),
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
    final fg = selected ? Colors.white : Colors.white.withValues(alpha: 0.7);
    final item = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          hoverColor: Colors.white.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 46,
            padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.brandGradient : null,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 22),
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
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            height: 68,
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
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _UserMenuAction.perfil,
                      child: ListTile(
                        leading: Icon(Icons.person_outline_rounded),
                        title: Text('Mi perfil'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: _UserMenuAction.datos,
                      child: ListTile(
                        leading: Icon(Icons.badge_outlined),
                        title: Text('Mis datos'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: _UserMenuAction.configuracion,
                      child: ListTile(
                        leading: Icon(Icons.settings_outlined),
                        title: Text('Configuración'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      key: Key('menu_logout'),
                      value: _UserMenuAction.salir,
                      child: ListTile(
                        leading: Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                        ),
                        title: Text(
                          'Cerrar sesión',
                          style: TextStyle(color: AppColors.error),
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
                        UserAvatar(profile: profile, size: 38),
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

/// Avatar con las iniciales del usuario.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.profile, this.size = 40});

  final UserProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        profile.iniciales,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Sección «Inicio»: bienvenida + módulo del ejercicio
// -----------------------------------------------------------------------------

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(mobile ? 16 : 28),
      child: MaxWidthBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WelcomeBanner(name: profile.primerNombre),
            // Contenido reemplazable: aquí se desarrolla cada ejercicio.
            // Hoy está vacío; al llenarlo, agrega un espacio antes, por ejemplo
            // SizedBox(height: mobile ? 20 : 28).
            const ExerciseModule(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.isMobile(context);
    return Container(
      padding: EdgeInsets.all(mobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.92),
            AppColors.violet.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $name!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: mobile ? 22 : 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bienvenido a tu espacio de trabajo.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: mobile ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
          if (!mobile)
            ExcludeSemantics(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
