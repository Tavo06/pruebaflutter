import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/app_exception.dart';
import 'google_android_delegate.dart';
import 'google_desktop_delegate_stub.dart'
    if (dart.library.io) 'google_desktop_delegate_io.dart';
import 'google_web_delegate.dart';

/// Obtiene la credencial de Google con el mecanismo propio de cada plataforma
/// y autentica en Firebase. Solo lo usa `AuthService`; las pantallas nunca
/// llaman a estas clases directamente.
///
/// | Plataforma | Mecanismo                                                  |
/// |------------|------------------------------------------------------------|
/// | Web        | `FirebaseAuth.signInWithPopup(GoogleAuthProvider())`       |
/// | Android    | `google_sign_in` (Credential Manager) → `signInWithCredential` |
/// | Windows    | OAuth 2.0 de escritorio (loopback + PKCE) → `signInWithCredential` |
abstract class GoogleSignInDelegate {
  const GoogleSignInDelegate();

  /// Abre el selector de cuenta de Google y autentica en Firebase.
  ///
  /// Devuelve `null` si el usuario cancela. Lanza [AppException] ante
  /// errores de configuración, red o credenciales.
  Future<UserCredential?> signIn(FirebaseAuth auth);

  /// Cierra la sesión del proveedor para que el próximo acceso vuelva a
  /// mostrar el selector de cuenta.
  Future<void> signOut() async {}

  /// Interrumpe un inicio de sesión en curso (solo es necesario cuando el
  /// flujo ocurre fuera de la app, como el navegador en Windows).
  void cancel() {}

  /// `true` si el flujo se abre fuera de la app y la interfaz debe ofrecer
  /// un botón para cancelarlo.
  bool get runsOutsideApp => false;
}

/// Elige la implementación adecuada para la plataforma actual.
GoogleSignInDelegate createGoogleSignInDelegate() {
  if (kIsWeb) return const WebGoogleSignInDelegate();
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return AndroidGoogleSignInDelegate();
    case TargetPlatform.windows:
      return createDesktopGoogleSignInDelegate();
    default:
      return const UnsupportedGoogleSignInDelegate();
  }
}

/// Plataformas sin configuración de Google (iOS, macOS, Linux en esta
/// plantilla). Informa de la limitación sin simular un acceso.
class UnsupportedGoogleSignInDelegate extends GoogleSignInDelegate {
  const UnsupportedGoogleSignInDelegate();

  @override
  Future<UserCredential?> signIn(FirebaseAuth auth) {
    throw const AppException(
      'El acceso con Google no está disponible en esta plataforma.',
    );
  }
}
