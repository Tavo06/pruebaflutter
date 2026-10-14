import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:proyectoflutter/app.dart';
import 'package:proyectoflutter/core/theme/app_theme.dart';
import 'package:proyectoflutter/exercises/finanzas/providers/movimientos_provider.dart';
import 'package:proyectoflutter/models/user_profile.dart';
import 'package:proyectoflutter/providers/auth_provider.dart';
import 'package:proyectoflutter/providers/theme_provider.dart';
import 'package:proyectoflutter/services/auth_service.dart';
import 'package:proyectoflutter/services/user_service.dart';

/// Dobles de prueba de Firebase (solo pruebas unitarias y de widgets; no
/// sustituyen las pruebas reales contra Firebase).
class TestBackend {
  TestBackend({MockUser? user, bool verifyEmailAutomatically = true})
    : auth = MockFirebaseAuth(
        mockUser: user,
        signedIn: user != null,
        verifyEmailAutomatically: verifyEmailAutomatically,
      ),
      db = FakeFirebaseFirestore();

  final MockFirebaseAuth auth;
  final FakeFirebaseFirestore db;

  AuthProvider createProvider() => AuthProvider(
    authService: AuthService(auth: auth),
    userService: UserService(firestore: db),
  );

  Future<void> seedProfile(
    String uid, {
    required bool registroCompleto,
    String email = 'ana@correo.com',
  }) {
    return db.collection('users').doc(uid).set({
      'uid': uid,
      'nombre': 'Ana María',
      'apellido': 'Pérez',
      'dni': '12345678',
      'fechaNacimiento': UserProfile.birthDateToTimestamp(DateTime(2000, 5, 1)),
      'correo': email,
      'registroCompleto': registroCompleto,
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    });
  }
}

RegistrationData sampleRegistration({String email = 'nuevo@correo.com'}) =>
    RegistrationData(
      nombre: 'Luis',
      apellido: 'Gómez',
      dni: '87654321',
      fechaNacimiento: DateTime(1999, 3, 15),
      correo: email,
    );

/// Espera a que el proveedor salga del estado inicial.
Future<void> settleProvider(AuthProvider p) async {
  for (var i = 0; i < 50 && p.status == AuthStatus.initializing; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Aplicación completa con proveedores de prueba.
Widget buildTestApp(AuthProvider auth) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider(null)),
    ChangeNotifierProvider.value(value: auth),
    ChangeNotifierProvider(create: (_) => MovimientosProvider()),
  ],
  child: const FlowApp(),
);

/// Envuelve un widget suelto con tema, localización y proveedor.
Widget wrapWidget(AuthProvider auth, Widget child) =>
    ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    );
