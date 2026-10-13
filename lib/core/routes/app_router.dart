import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/verify_email_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../widgets/loading_indicator.dart';

/// Rutas de la aplicación.
///
/// El acceso NO depende de la URL ni de la pila de navegación: cualquier ruta
/// (incluidas las escritas a mano en la barra del navegador) pasa por
/// [AuthGate], que decide qué mostrar según el estado real de Firebase.
/// Así el botón «atrás» no puede volver a una pantalla privada tras cerrar
/// sesión.
class AppRouter {
  AppRouter._();

  static const String root = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: root),
      builder: (_) => const AuthGate(),
    );
  }
}

/// Muestra la pantalla que corresponde al estado de autenticación.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);

    final Widget child = switch (status) {
      AuthStatus.initializing => const LoadingIndicator(
        message: 'Cargando…',
      ),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.pendingVerification ||
      AuthStatus.pendingPassword => const VerifyEmailScreen(),
      AuthStatus.authenticated => const HomeScreen(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        // Ambos estados pendientes comparten pantalla para no perder su estado.
        key: ValueKey(
          status == AuthStatus.pendingPassword
              ? AuthStatus.pendingVerification
              : status,
        ),
        child: child,
      ),
    );
  }
}
