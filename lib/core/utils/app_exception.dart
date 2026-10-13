import 'package:firebase_auth/firebase_auth.dart';

/// Campo del formulario al que se asocia un error, si corresponde.
enum ErrorField { email, dni, password, general }

/// Error con un mensaje apto para mostrar al usuario.
///
/// Nunca contiene trazas, códigos internos ni datos personales.
class AppException implements Exception {
  const AppException(this.message, {this.field = ErrorField.general});

  final String message;
  final ErrorField field;

  @override
  String toString() => message;

  /// Convierte cualquier error de Firebase u otro origen en un mensaje claro.
  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseAuthException) return _fromAuth(error.code);
    if (error is FirebaseException) return _fromFirestore(error.code);
    return const AppException(
      'Ocurrió un error inesperado. Inténtalo de nuevo.',
    );
  }

  static AppException _fromAuth(String code) {
    switch (code) {
      case 'invalid-email':
        return const AppException(
          'El correo electrónico no es válido.',
          field: ErrorField.email,
        );
      case 'email-already-in-use':
        return const AppException(
          'Este correo ya está registrado o tiene un registro pendiente.',
          field: ErrorField.email,
        );
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return const AppException('Correo o contraseña incorrectos.');
      case 'user-disabled':
        return const AppException(
          'Esta cuenta está deshabilitada. Contacta al administrador.',
        );
      case 'too-many-requests':
        return const AppException(
          'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
        );
      case 'network-request-failed':
        return const AppException(
          'No hay conexión con el servidor. Revisa tu conexión a internet.',
        );
      case 'weak-password':
        return const AppException(
          'La contraseña es demasiado débil.',
          field: ErrorField.password,
        );
      case 'requires-recent-login':
        return const AppException(
          'Por seguridad, necesitas volver a iniciar sesión para continuar.',
        );
      case 'operation-not-allowed':
        return const AppException(
          'El acceso con correo y contraseña no está habilitado en el '
          'servidor.',
        );
      case 'user-token-expired':
      case 'invalid-user-token':
        return const AppException(
          'Tu sesión ha expirado. Inicia sesión de nuevo.',
        );
      default:
        return const AppException(
          'No se pudo completar la operación. Inténtalo de nuevo.',
        );
    }
  }

  static AppException _fromFirestore(String code) {
    switch (code) {
      case 'permission-denied':
        return const AppException(
          'No tienes permiso para realizar esta operación.',
        );
      case 'unavailable':
      case 'deadline-exceeded':
        return const AppException(
          'No hay conexión con el servidor. Revisa tu conexión a internet.',
        );
      default:
        return const AppException(
          'No se pudieron procesar tus datos. Inténtalo de nuevo.',
        );
    }
  }
}
