import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'exercises/finanzas/providers/movimientos_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseService.initialize();
  } catch (_) {
    runApp(const _StartupErrorApp());
    return;
  }

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    // Sin preferencias locales la app funciona con los valores por defecto.
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: AuthService(),
            userService: UserService(),
            prefs: prefs,
          ),
        ),
        // Estado global del ejercicio de finanzas (ingresos y gastos).
        ChangeNotifierProvider(create: (_) => MovimientosProvider()),
      ],
      child: const FlowApp(),
    ),
  );
}

/// Pantalla mínima si Firebase no puede inicializarse.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se pudo iniciar la aplicación. Revisa tu conexión e '
              'inténtalo de nuevo.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
