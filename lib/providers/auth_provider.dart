import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/app_exception.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Estado de acceso de la aplicación.
enum AuthStatus {
  /// Comprobando la sesión guardada por Firebase.
  initializing,

  /// Sin sesión: se muestra el login.
  unauthenticated,

  /// Cuenta creada, correo aún sin verificar en Firebase.
  pendingVerification,

  /// Correo verificado, falta crear la contraseña definitiva.
  pendingPassword,

  /// Cuenta de Google sin datos personales (DNI, fecha, teléfono): debe
  /// completarlos antes de entrar al dashboard.
  pendingProfile,

  /// Correo verificado y registro completo: acceso al dashboard.
  authenticated,
}

/// Tipo de aviso que se muestra una sola vez en el login.
enum FlashType { success, info, error }

class FlashMessage {
  const FlashMessage(this.text, this.type);

  final String text;
  final FlashType type;
}

/// Estado reactivo de autenticación y del perfil del usuario.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
    required UserService userService,
    this._prefs,
  }) : _auth = authService,
       _users = userService {
    _subscription = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final AuthService _auth;
  final UserService _users;
  final SharedPreferences? _prefs;
  late final StreamSubscription<User?> _subscription;

  AuthStatus _status = AuthStatus.initializing;
  UserProfile? _profile;
  FlashMessage? _flash;
  String? _lastEmail;
  DateTime? _lastVerificationSentAt;
  bool _verificationSendFailed = false;

  /// Mientras es `true`, los eventos de Firebase se ignoran porque la propia
  /// operación en curso decide el estado final.
  bool _handlingOperation = false;

  /// UID ya evaluado, para no repetir la evaluación por eventos duplicados.
  String? _handledUid;
  bool _handledOnce = false;

  AuthStatus get status => _status;
  UserProfile? get profile => _profile;

  /// Correo de la cuenta en proceso de registro.
  String? get pendingEmail => _auth.currentUser?.email ?? _profile?.correo;

  /// Último correo usado, para facilitar el inicio de sesión tras registrarse.
  String? get lastEmail => _lastEmail;

  bool get verificationSendFailed => _verificationSendFailed;

  bool get rememberSession =>
      _prefs?.getBool(PrefsKeys.rememberSession) ?? true;

  set rememberSession(bool value) {
    _prefs?.setBool(PrefsKeys.rememberSession, value);
    notifyListeners();
  }

  /// Segundos restantes antes de poder reenviar la verificación.
  int get resendCooldown {
    final sent = _lastVerificationSentAt;
    if (sent == null) return 0;
    final elapsed = DateTime.now().difference(sent).inSeconds;
    final left = AppConstants.resendCooldownSeconds - elapsed;
    return left > 0 ? left : 0;
  }

  /// Devuelve y limpia el aviso pendiente.
  FlashMessage? takeFlash() {
    final f = _flash;
    _flash = null;
    return f;
  }

  // ---------------------------------------------------------------------------
  // Evaluación del estado
  // ---------------------------------------------------------------------------

  Future<void> _onAuthChanged(User? user) async {
    if (_handlingOperation) return;
    if (_handledOnce && user?.uid == _handledUid) return;
    if (user == null) {
      _setUnauthenticated();
      return;
    }
    try {
      await _evaluate(user, reload: true);
    } on AppException catch (e) {
      await _auth.signOut();
      _setUnauthenticated(flash: FlashMessage(e.message, FlashType.error));
    }
  }

  /// Decide a qué parte de la aplicación puede acceder [user].
  Future<void> _evaluate(User user, {bool reload = false}) async {
    var verified = user.emailVerified;
    if (reload) {
      try {
        verified = await _auth.reloadAndCheckVerified();
      } on AppException {
        // Sin conexión se usa el último estado conocido de Firebase.
        verified = _auth.currentUser?.emailVerified ?? false;
      }
    }
    var profile = await _users.fetchProfile(user.uid);
    if (profile == null && AuthService.isGoogleUser(user)) {
      profile = await _createGoogleProfile(user, verified: verified);
      if (profile == null) return;
    }
    if (profile == null) {
      await _auth.signOut();
      _setUnauthenticated(
        flash: const FlashMessage(
          'No encontramos los datos de registro de esta cuenta. '
          'Contacta al administrador.',
          FlashType.error,
        ),
      );
      return;
    }
    _profile = profile;
    _handledUid = user.uid;
    _handledOnce = true;
    if (!profile.registroCompleto && !profile.tieneDatosPersonales) {
      // Perfil iniciado con Google: faltan los datos personales.
      if (!verified) {
        await _auth.signOut();
        _setUnauthenticated(flash: _unverifiedGoogleFlash);
        return;
      }
      _status = AuthStatus.pendingProfile;
    } else if (!verified) {
      _status = AuthStatus.pendingVerification;
    } else if (!profile.registroCompleto) {
      _status = AuthStatus.pendingPassword;
    } else {
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  static const _unverifiedGoogleFlash = FlashMessage(
    'Google no confirmó la verificación de este correo. Usa otra cuenta o '
    'regístrate con tu correo electrónico.',
    FlashType.error,
  );

  /// Primer acceso con Google: crea el perfil inicial solo con el nombre y el
  /// correo del proveedor. Devuelve `null` si cerró la sesión.
  Future<UserProfile?> _createGoogleProfile(
    User user, {
    required bool verified,
  }) async {
    final email = user.email;
    if (!verified || email == null) {
      await _auth.signOut();
      _setUnauthenticated(flash: _unverifiedGoogleFlash);
      return null;
    }
    final (nombre, apellido) = splitDisplayName(user.displayName);
    try {
      await _users.createGoogleProfile(
        uid: user.uid,
        correo: email,
        nombre: nombre,
        apellido: apellido,
      );
      return await _users.fetchProfile(user.uid);
    } on AppException {
      throw const AppException(
        'Iniciaste sesión con Google, pero no pudimos crear tu perfil. '
        'Inténtalo de nuevo más tarde.',
      );
    }
  }

  /// Separa el nombre visible de Google en nombre y apellido. Solo es una
  /// sugerencia: el usuario lo revisa al completar su perfil.
  static (String, String) splitDisplayName(String? displayName) {
    final parts = (displayName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    String clip(String v) => v.length > AppConstants.maxNameLength
        ? v.substring(0, AppConstants.maxNameLength)
        : v;
    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (clip(parts.first), '');
    // «Nombre Apellido(s)»; con 4 o más palabras se asumen dos nombres.
    final split = parts.length >= 4 ? 2 : 1;
    return (
      clip(parts.take(split).join(' ')),
      clip(parts.skip(split).join(' ')),
    );
  }

  void _setUnauthenticated({FlashMessage? flash}) {
    _profile = null;
    _handledUid = null;
    _handledOnce = true;
    _lastVerificationSentAt = null;
    _verificationSendFailed = false;
    if (flash != null) _flash = flash;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    _handlingOperation = true;
    try {
      return await action();
    } finally {
      _handlingOperation = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Inicio y cierre de sesión
  // ---------------------------------------------------------------------------

  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final user = await _auth.signIn(
        email: email,
        password: password,
        remember: rememberSession,
      );
      _lastEmail = email;
      try {
        await _evaluate(user, reload: true);
      } catch (e) {
        await _auth.signOut();
        _setUnauthenticated();
        throw AppException.from(e);
      }
    });
  }

  /// Acceso o alta con Google (mismo flujo desde el login y el registro).
  ///
  /// Devuelve `false` si el usuario canceló el selector de cuenta. Tras
  /// autenticar, recupera el perfil del UID o crea uno inicial y decide el
  /// destino: dashboard o «completa tu perfil».
  Future<bool> signInWithGoogle() {
    return _guard(() async {
      final user = await _auth.signInWithGoogle(remember: rememberSession);
      if (user == null) return false;
      _lastEmail = user.email;
      try {
        await _evaluate(user, reload: true);
      } catch (e) {
        await _auth.signOut();
        _setUnauthenticated();
        throw AppException.from(e);
      }
      return true;
    });
  }

  /// Interrumpe un acceso con Google en curso (navegador en Windows).
  void cancelGoogleSignIn() => _auth.cancelGoogleSignIn();

  bool get googleRunsOutsideApp => _auth.googleRunsOutsideApp;

  /// `true` si la sesión actual tiene Google como proveedor.
  bool get isGoogleAccount {
    final user = _auth.currentUser;
    return user != null && AuthService.isGoogleUser(user);
  }

  /// Completa un perfil iniciado con Google y da acceso al dashboard.
  Future<void> completePendingProfile(RegistrationData data) {
    return _guard(() async {
      final user = _auth.currentUser;
      if (user == null || _status != AuthStatus.pendingProfile) {
        throw const AppException(
          'Tu sesión ha finalizado. Inicia sesión de nuevo.',
        );
      }
      // El estado de verificación se consulta a Firebase, no a la interfaz.
      final verified = await _auth.reloadAndCheckVerified();
      if (!verified) {
        throw const AppException('Tu correo aún no está verificado.');
      }
      await _users.completeGoogleProfile(uid: user.uid, data: data);
      _profile = await _users.fetchProfile(user.uid);
      if (_profile?.registroCompleto != true) {
        throw const AppException(
          'No pudimos confirmar tus datos. Inténtalo de nuevo.',
        );
      }
      _status = AuthStatus.authenticated;
      notifyListeners();
    });
  }

  /// Cierra la sesión y libera los datos privados en memoria.
  Future<void> signOut() {
    return _guard(() async {
      await _auth.signOut();
      _setUnauthenticated();
    });
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordReset(email);

  // ---------------------------------------------------------------------------
  // Registro
  // ---------------------------------------------------------------------------

  /// Paso 1: crea la cuenta pendiente, guarda el perfil y envía el enlace.
  Future<void> startRegistration(RegistrationData data) {
    return _guard(() async {
      final user = await _auth.createPendingAccount(data.correo);
      try {
        await _users.createPendingProfile(
          uid: user.uid,
          correo: user.email ?? data.correo,
          data: data,
        );
      } catch (e) {
        // Revierte la cuenta para no dejar un registro imposible de retomar.
        try {
          await _auth.deleteCurrentUser();
        } catch (_) {
          await _auth.signOut();
        }
        _setUnauthenticated();
        throw AppException.from(e);
      }

      try {
        await _auth.sendEmailVerification();
        _verificationSendFailed = false;
      } on AppException {
        // La cuenta existe: el usuario puede reenviar desde la verificación.
        _verificationSendFailed = true;
      }
      _lastVerificationSentAt = DateTime.now();
      _lastEmail = user.email ?? data.correo;
      _profile = await _users.fetchProfile(user.uid);
      _handledUid = user.uid;
      _handledOnce = true;
      _status = AuthStatus.pendingVerification;
      notifyListeners();
    });
  }

  /// Paso 2: consulta a Firebase si el correo ya fue verificado.
  Future<bool> checkEmailVerified() {
    return _guard(() async {
      final verified = await _auth.reloadAndCheckVerified();
      if (verified && _status == AuthStatus.pendingVerification) {
        _status = AuthStatus.pendingPassword;
        notifyListeners();
      }
      return verified;
    });
  }

  /// Alternativa: verifica pegando el enlace recibido por correo.
  Future<bool> verifyWithLink(String link) {
    return _guard(() async {
      final verified = await _auth.applyVerificationLink(link);
      if (verified && _status == AuthStatus.pendingVerification) {
        _status = AuthStatus.pendingPassword;
        notifyListeners();
      }
      return verified;
    });
  }

  Future<void> resendVerification() {
    return _guard(() async {
      if (resendCooldown > 0) {
        throw AppException(
          'Espera $resendCooldown s antes de reenviar el correo.',
        );
      }
      await _auth.sendEmailVerification();
      _verificationSendFailed = false;
      _lastVerificationSentAt = DateTime.now();
      notifyListeners();
    });
  }

  /// Paso 3: crea la contraseña definitiva tras confirmar la verificación.
  Future<void> completeRegistration(String password) {
    return _guard(() async {
      // Se vuelve a comprobar contra Firebase; nunca se confía en el estado
      // local.
      final verified = await _auth.reloadAndCheckVerified();
      if (!verified) {
        _status = AuthStatus.pendingVerification;
        notifyListeners();
        throw const AppException(
          'Tu correo aún no está verificado. Abre el enlace que te enviamos.',
        );
      }
      final user = _auth.currentUser!;
      await _auth.setDefinitivePassword(password);
      await _users.markRegistrationComplete(user.uid);
      _lastEmail = user.email;
      await _auth.signOut();
      _setUnauthenticated(
        flash: const FlashMessage(
          'Tu cuenta está lista. Inicia sesión con tu correo y tu nueva '
          'contraseña.',
          FlashType.success,
        ),
      );
    });
  }

  /// Cancela un registro sin completar y elimina la cuenta pendiente.
  Future<void> cancelRegistration() {
    return _guard(() async {
      final profile = _profile;
      if (profile == null || profile.registroCompleto) {
        await _auth.signOut();
        _setUnauthenticated();
        return;
      }
      if (!_auth.canDeleteWithoutReauth) {
        await _auth.signOut();
        _setUnauthenticated(
          flash: const FlashMessage(
            'Cerramos la sesión. Tu registro sigue pendiente: usa '
            '«¿Olvidaste tu contraseña?» si deseas retomarlo.',
            FlashType.info,
          ),
        );
        return;
      }
      await _auth.prepareSensitiveOperation();
      await _users.deletePendingProfile(uid: profile.uid, dni: profile.dni);
      try {
        await _auth.deleteCurrentUser();
      } catch (_) {
        await _auth.signOut();
      }
      _setUnauthenticated(
        flash: const FlashMessage('Se canceló el registro.', FlashType.info),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Perfil
  // ---------------------------------------------------------------------------

  /// Guarda los datos editables. Si [telefono] es `null` no se modifica.
  Future<void> updateProfileData({
    required String nombre,
    required String apellido,
    String? telefono,
  }) async {
    final profile = _profile;
    if (profile == null) return;
    await _users.updateProfileData(
      uid: profile.uid,
      nombre: nombre,
      apellido: apellido,
      telefono: telefono,
    );
    _profile = profile.copyWith(
      nombre: nombre,
      apellido: apellido,
      telefono: telefono,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
