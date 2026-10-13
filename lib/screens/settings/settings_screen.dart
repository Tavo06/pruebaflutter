import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/breakpoints.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/responsive_layout.dart';

/// Ajustes de la aplicación. Solo se guardan preferencias no sensibles.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final mobile = Breakpoints.isMobile(context);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apariencia', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Elige el tema de la aplicación. Se guarda en este '
                      'dispositivo.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        key: const Key('theme_selector'),
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Claro'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Oscuro'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_outlined),
                            label: Text('Sistema'),
                          ),
                        ],
                        selected: {themeProvider.mode},
                        onSelectionChanged: (s) =>
                            themeProvider.setMode(s.first),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Acerca de'),
                subtitle: Text(
                  '${AppConstants.appName} · versión ${AppConstants.appVersion}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
