import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

class FlowApp extends StatefulWidget {
  const FlowApp({super.key});

  @override
  State<FlowApp> createState() => _FlowAppState();
}

class _FlowAppState extends State<FlowApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthProvider _auth;
  AuthStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    _lastStatus = _auth.status;
    _auth.addListener(_onAuthChanged);
  }

  /// Al cambiar el estado de acceso se cierran modales y rutas apiladas, de
  /// modo que ninguna vista privada quede abierta tras cerrar sesión.
  void _onAuthChanged() {
    if (_auth.status == _lastStatus) return;
    _lastStatus = _auth.status;
    _navigatorKey.currentState?.popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.select<ThemeProvider, ThemeMode>((t) => t.mode);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRouter.root,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
