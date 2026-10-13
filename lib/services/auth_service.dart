import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/app_exception.dart';

/// Operaciones de Firebase Authentication, separadas de la interfaz.
///
/// Estrategia de registro (verificar el correo antes de crear la contraseña):
/// 1. Se crea la cuenta con una contraseña temporal aleatoria que solo vive en
///    memoria durante la sesión (nunca se guarda ni se muestra).
/// 2. Firebase envía el enlace real de verificación.
/// 3. El estado se comprueba contra Firebase con `reload()`.
/// 4. Tras verificar, la contraseña definitiva sustituye a la temporal con
///    `updatePassword()`.
/// La sesión que Firebase mantiene permite retomar el proceso si se cierra la
/// aplicación.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Contraseña temporal del registro en curso. Solo en memoria.
  String? _tempPassword;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Inicia sesión. En web, [remember] decide si la sesión sobrevive al
  /// cierre del navegador; en Android y Windows la sesión siempre persiste.
  Future<User> signIn({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    try {
      if (kIsWeb) {
        await _auth.setPersistence(
          remember ? Persistence.LOCAL : Persistence.SESSION,
        );
      }
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user!;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Crea la cuenta pendiente con una contraseña temporal y envía el correo
  /// de verificación de Firebase.
  Future<User> createPendingAccount(String email) async {
    try {
      if (kIsWeb) {
        // La sesión del registro debe sobrevivir al cierre del navegador
        // para poder retomarlo.
        await _auth.setPersistence(Persistence.LOCAL);
      }
      final temp = _generateTempPassword();
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: temp,
      );
      _tempPassword = temp;
      return cred.user!;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _requireUser();
    try {
      await _auth.setLanguageCode('es');
    } catch (_) {
      // El idioma del correo es opcional; no debe bloquear el envío.
    }
    try {
      await user.sendEmailVerification();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Recarga el usuario desde Firebase y devuelve el estado real de
  /// verificación. Si está verificado, refresca el token para que las reglas
  /// de Firestore vean `email_verified == true`.
  Future<bool> reloadAndCheckVerified() async {
    final user = _requireUser();
    try {
      await user.reload();
      final refreshed = _auth.currentUser;
      final verified = refreshed?.emailVerified ?? false;
      if (verified) await refreshed!.getIdToken(true);
      return verified;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Aplica el enlace de verificación pegado por el usuario (o su código).
  ///
  /// Alternativa cuando la página de Firebase no puede abrir el enlace, por
  /// ejemplo si el cliente de correo lo modificó. La verificación la realiza
  /// Firebase con `applyActionCode`; después se consulta el estado real.
  Future<bool> applyVerificationLink(String input) async {
    final code = extractOobCode(input);
    if (code == null) {
      throw const AppException(
        'No encontramos un código de verificación en el enlace pegado.',
      );
    }
    try {
      final info = await _auth.checkActionCode(code);
      if (info.operation != ActionCodeInfoOperation.verifyEmail) {
        throw const AppException('Ese enlace no es de verificación de correo.');
      }
      if (info.data['email'] != null &&
          (info.data['email'] as String).toLowerCase() !=
              _requireUser().email?.toLowerCase()) {
        throw const AppException(
          'Ese enlace corresponde a otro correo electrónico.',
        );
      }
      await _auth.applyActionCode(code);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-action-code' || e.code == 'expired-action-code') {
        throw const AppException(
          'El enlace no es válido o ya caducó. Pulsa «Reenviar correo».',
        );
      }
      throw AppException.from(e);
    }
    return reloadAndCheckVerified();
  }

  /// Obtiene el `oobCode` de un enlace de Firebase, aunque venga envuelto en
  /// otra URL (protección de enlaces del correo) o con `&amp;`.
  static String? extractOobCode(String input) {
    var text = input.trim();
    for (var i = 0; i < 3; i++) {
      final match = RegExp(r'oobCode(?:=|%3D)([A-Za-z0-9_\-]+)').firstMatch(text);
      if (match != null) return match.group(1);
      final decoded = Uri.decodeFull(text);
      if (decoded == text) break;
      text = decoded;
    }
    if (RegExp(r'^[A-Za-z0-9_\-]{20,}$').hasMatch(input.trim())) {
      return input.trim();
    }
    return null;
  }

  /// Sustituye la contraseña temporal por la definitiva.
  Future<void> setDefinitivePassword(String password) async {
    final user = _requireUser();
    try {
      await user.updatePassword(password);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') throw AppException.from(e);
      if (_tempPassword == null) {
        throw const AppException(
          'Por seguridad, tu sesión de registro ha caducado. Usa '
          '«¿Olvidaste tu contraseña?» para establecer tu contraseña y '
          'después inicia sesión para terminar el registro.',
        );
      }
      try {
        await _reauthenticateWithTemp(user);
        await user.updatePassword(password);
      } catch (e) {
        throw AppException.from(e);
      }
    } catch (e) {
      throw AppException.from(e);
    }
    _tempPassword = null;
  }

  /// Indica si la cuenta actual puede eliminarse sin pedir credenciales:
  /// se conoce la contraseña temporal o el inicio de sesión es reciente.
  bool get canDeleteWithoutReauth {
    if (_tempPassword != null) return true;
    final last = currentUser?.metadata.lastSignInTime;
    if (last == null) return false;
    return DateTime.now().difference(last) < const Duration(minutes: 4);
  }

  /// Reautentica (si es posible) antes de una operación sensible.
  Future<void> prepareSensitiveOperation() async {
    final user = _requireUser();
    if (_tempPassword == null) return;
    try {
      await _reauthenticateWithTemp(user);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Elimina la cuenta de Firebase Authentication del usuario actual.
  Future<void> deleteCurrentUser() async {
    final user = _requireUser();
    try {
      await user.delete();
      _tempPassword = null;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Envía el enlace de restablecimiento. No revela si el correo existe.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.setLanguageCode('es');
    } catch (_) {}
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') return;
      throw AppException.from(e);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> signOut() async {
    _tempPassword = null;
    await _auth.signOut();
  }

  Future<void> _reauthenticateWithTemp(User user) async {
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: _tempPassword!,
    );
    await user.reauthenticateWithCredential(cred);
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        'Tu sesión ha finalizado. Inicia sesión de nuevo.',
      );
    }
    return user;
  }

  /// Contraseña aleatoria de 32 caracteres generada con un RNG seguro.
  static String _generateTempPassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%*-_';
    final rnd = Random.secure();
    return List.generate(32, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
