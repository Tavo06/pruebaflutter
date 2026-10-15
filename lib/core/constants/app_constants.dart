/// Identidad y parámetros globales de la aplicación.
///
/// Cambia aquí el nombre, el lema y los valores de configuración para
/// reutilizar la plantilla en otro proyecto.
class AppConstants {
  AppConstants._();

  static const String appName = 'TransporteCalc';
  static const String appTagline = 'El costo de cada viaje, claro y al instante.';
  static const String appVersion = '1.0.0';

  /// Segundos de espera entre reenvíos del correo de verificación.
  static const int resendCooldownSeconds = 60;

  /// Longitudes de los campos del registro.
  static const int maxNameLength = 50;
  static const int dniLength = 8;
  static const int phoneLength = 9;
}

/// Nombres de colecciones de Cloud Firestore.
class FirestoreCollections {
  FirestoreCollections._();

  /// Perfil de cada usuario: `users/{uid}`.
  static const String users = 'users';

  /// Índice de unicidad del DNI: `dnis/{dni}` → `{ uid }`.
  static const String dnis = 'dnis';
}

/// Claves de preferencias locales. Solo se guardan ajustes no sensibles.
class PrefsKeys {
  PrefsKeys._();

  static const String themeMode = 'pref_theme_mode';
  static const String rememberSession = 'pref_remember_session';
}
