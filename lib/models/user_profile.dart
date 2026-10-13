import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil del usuario almacenado en `users/{uid}`.
///
/// No contiene contraseñas ni credenciales.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.fechaNacimiento,
    required this.correo,
    required this.registroCompleto,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String nombre;
  final String apellido;
  final String dni;

  /// Fecha de nacimiento (solo día, mes y año).
  final DateTime fechaNacimiento;
  final String correo;
  final bool registroCompleto;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get nombreCompleto => '$nombre $apellido';

  String get iniciales {
    final a = nombre.isNotEmpty ? nombre[0] : '';
    final b = apellido.isNotEmpty ? apellido[0] : '';
    return (a + b).toUpperCase();
  }

  /// Primer nombre, para saludos.
  String get primerNombre => nombre.split(' ').first;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // La fecha se guarda a medianoche UTC para evitar desfases de zona horaria.
    final birth = (map['fechaNacimiento'] as Timestamp).toDate().toUtc();
    return UserProfile(
      uid: map['uid'] as String,
      nombre: map['nombre'] as String,
      apellido: map['apellido'] as String,
      dni: map['dni'] as String,
      fechaNacimiento: DateTime(birth.year, birth.month, birth.day),
      correo: map['correo'] as String,
      registroCompleto: map['registroCompleto'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Timestamp birthDateToTimestamp(DateTime date) =>
      Timestamp.fromDate(DateTime.utc(date.year, date.month, date.day));

  UserProfile copyWith({
    String? nombre,
    String? apellido,
    bool? registroCompleto,
  }) {
    return UserProfile(
      uid: uid,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      dni: dni,
      fechaNacimiento: fechaNacimiento,
      correo: correo,
      registroCompleto: registroCompleto ?? this.registroCompleto,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Datos del formulario de registro antes de crear la cuenta.
class RegistrationData {
  const RegistrationData({
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.fechaNacimiento,
    required this.correo,
  });

  final String nombre;
  final String apellido;
  final String dni;
  final DateTime fechaNacimiento;
  final String correo;
}
