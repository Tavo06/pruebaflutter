import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/utils/app_exception.dart';
import 'google_sign_in_delegate.dart';

/// Android: selector de cuenta oficial (Credential Manager) mediante
/// `google_sign_in`; el ID token resultante se entrega a Firebase.
///
/// El identificador del cliente web (`serverClientId`) se lee del recurso
/// `default_web_client_id` que el plugin de Google Services genera a partir de
/// `google-services.json`. Ese recurso solo existe cuando Google está
/// habilitado en Firebase y la huella SHA-1 de la app está registrada. Como
/// alternativa puede pasarse con `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
class AndroidGoogleSignInDelegate extends GoogleSignInDelegate {
  AndroidGoogleSignInDelegate();

  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  Future<void>? _initialization;

  Future<void> _ensureInitialized() {
    return _initialization ??= GoogleSignIn.instance
        .initialize(
          serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
        )
        .catchError((Object e) {
          _initialization = null; // Permite reintentar.
          throw e;
        });
  }

  @override
  Future<UserCredential?> signIn(FirebaseAuth auth) async {
    final String? idToken;
    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email'],
      );
      idToken = account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          return null;
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw const AppException(
            'Google Sign-In no está configurado para Android. Habilita Google '
            'en Firebase, registra la huella SHA-1 de la app y descarga de '
            'nuevo google-services.json.',
          );
        case GoogleSignInExceptionCode.uiUnavailable:
          throw const AppException(
            'No se pudo mostrar el selector de cuentas de Google en este '
            'dispositivo.',
          );
        default:
          throw const AppException(
            'No se pudo iniciar sesión con Google. Comprueba tu conexión e '
            'inténtalo de nuevo.',
          );
      }
    } catch (e) {
      throw AppException.google(e);
    }

    if (idToken == null) {
      throw const AppException(
        'Google no devolvió credenciales válidas. Inténtalo de nuevo.',
      );
    }
    return auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  @override
  Future<void> signOut() async {
    if (_initialization == null) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // La sesión de Firebase ya se cerró; esto solo afecta al selector.
    }
  }
}
