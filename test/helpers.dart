import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:proyectoflutter/app.dart';
import 'package:proyectoflutter/core/theme/app_theme.dart';
import 'package:proyectoflutter/models/user_profile.dart';
import 'package:proyectoflutter/providers/auth_provider.dart';
import 'package:proyectoflutter/providers/theme_provider.dart';
import 'package:proyectoflutter/services/auth_service.dart';
import 'package:proyectoflutter/services/google/google_sign_in_delegate.dart';
import 'package:proyectoflutter/services/user_service.dart';

/// Dobles de prueba de Firebase (solo pruebas unitarias y de widgets; no
/// sustituyen las pruebas reales contra Firebase).
class TestBackend {
  TestBackend({
    MockUser? user,
    bool? signedIn,
    bool verifyEmailAutomatically = true,
    FakeGoogleDelegate? google,
  }) : auth = MockFirebaseAuth(
         mockUser: user,
         signedIn: signedIn ?? user != null,
         verifyEmailAutomatically: verifyEmailAutomatically,
       ),
       google = google ?? FakeGoogleDelegate(),
       db = FakeFirebaseFirestore();

  final MockFirebaseAuth auth;
  final FakeGoogleDelegate google;
  final FakeFirebaseFirestore db;

  AuthProvider createProvider() => AuthProvider(
    authService: AuthService(auth: auth, google: google),
    userService: UserService(firestore: db),
  );

  /// Perfil creado por el registro por correo. Con [telefono] `null` simula
  /// un documento antiguo, anterior al campo de teléfono.
  Future<void> seedProfile(
    String uid, {
    required bool registroCompleto,
    String email = 'ana@correo.com',
    String? telefono = '912345678',
  }) {
    return db.collection('users').doc(uid).set({
      'uid': uid,
      'nombre': 'Ana María',
      'apellido': 'Pérez',
      'dni': '12345678',
      'fechaNacimiento': UserProfile.birthDateToTimestamp(DateTime(2000, 5, 1)),
      'telefono': ?telefono,
      'correo': email,
      'registroCompleto': registroCompleto,
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    });
  }

  Future<Map<String, dynamic>?> userDoc(String uid) async =>
      (await db.collection('users').doc(uid).get()).data();
}

/// Usuario que Firebase devolvería tras autenticarse con Google.
MockUser googleUser({
  String uid = 'g1',
  String email = 'lucia@gmail.com',
  String? displayName = 'Lucía Torres Ramos',
  bool verified = true,
}) => MockUser(
  uid: uid,
  email: email,
  displayName: displayName,
  isEmailVerified: verified,
  providerData: [
    // ignore: invalid_use_of_protected_member
    UserInfo.fromJson({
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isAnonymous': false,
      'isEmailVerified': verified,
      'providerId': 'google.com',
    }),
  ],
);

enum GoogleOutcome { success, cancel, error }

/// Sustituye el selector de cuenta de Google. Con [GoogleOutcome.success]
/// entrega una credencial de Google al Firebase simulado, que inicia sesión
/// con el `MockUser` configurado. No contacta con Google ni con Firebase.
class FakeGoogleDelegate extends GoogleSignInDelegate {
  FakeGoogleDelegate({this.outcome = GoogleOutcome.success, this.errorCode});

  GoogleOutcome outcome;
  String? errorCode;
  int calls = 0;
  int signOuts = 0;

  @override
  Future<UserCredential?> signIn(FirebaseAuth auth) async {
    calls++;
    switch (outcome) {
      case GoogleOutcome.cancel:
        return null;
      case GoogleOutcome.error:
        throw FirebaseAuthException(code: errorCode ?? 'internal-error');
      case GoogleOutcome.success:
        return auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: 'id-token-de-prueba'),
        );
    }
  }

  @override
  Future<void> signOut() async => signOuts++;
}

RegistrationData sampleRegistration({String email = 'nuevo@correo.com'}) =>
    RegistrationData(
      nombre: 'Luis',
      apellido: 'Gómez',
      dni: '87654321',
      fechaNacimiento: DateTime(1999, 3, 15),
      telefono: '987654321',
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
