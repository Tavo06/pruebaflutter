import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil del usuario almacenado en `users/{uid}`.
///
/// No contiene contraseñas ni credenciales.
///
/// [dni], [fechaNacimiento] y [telefono] pueden faltar:
/// - Un perfil iniciado con Google no tiene DNI ni fecha hasta que el usuario
///   completa sus datos (estado «perfil pendiente»).
/// - Los perfiles creados antes de añadir el teléfono no tienen `telefono`;
///   siguen funcionando y el usuario puede completarlo desde «Mis datos».
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.registroCompleto,
    this.dni,
    this.fechaNacimiento,
    this.telefono,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String nombre;
  final String apellido;
  final String? dni;

  /// Fecha de nacimiento (solo día, mes y año).
  final DateTime? fechaNacimiento;

  /// Número de teléfono de nueve dígitos.
  final String? telefono;
  final String correo;
  final bool registroCompleto;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get nombreCompleto => '$nombre $apellido'.trim();

  String get iniciales {
    final a = nombre.isNotEmpty ? nombre[0] : '';
    final b = apellido.isNotEmpty ? apellido[0] : '';
    final r = (a + b).toUpperCase();
    return r.isEmpty && correo.isNotEmpty ? correo[0].toUpperCase() : r;
  }

  /// Primer nombre, para saludos.
  String get primerNombre {
    final first = nombre.split(' ').first;
    return first.isEmpty ? correo.split('@').first : first;
  }

  /// `true` si el perfil ya tiene los datos personales del registro
  /// (DNI y fecha). Los perfiles iniciados con Google no los tienen hasta que
  /// el usuario los completa.
  bool get tieneDatosPersonales => dni != null && fechaNacimiento != null;

  bool get tieneTelefono => telefono != null && telefono!.isNotEmpty;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // La fecha se guarda a medianoche UTC para evitar desfases de zona horaria.
    final birth = (map['fechaNacimiento'] as Timestamp?)?.toDate().toUtc();
    return UserProfile(
      uid: map['uid'] as String,
      nombre: map['nombre'] as String? ?? '',
      apellido: map['apellido'] as String? ?? '',
      dni: map['dni'] as String?,
      fechaNacimiento: birth == null
          ? null
          : DateTime(birth.year, birth.month, birth.day),
      telefono: map['telefono'] as String?,
      correo: map['correo'] as String? ?? '',
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
    String? telefono,
    bool? registroCompleto,
  }) {
    return UserProfile(
      uid: uid,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      dni: dni,
      fechaNacimiento: fechaNacimiento,
      telefono: telefono ?? this.telefono,
      correo: correo,
      registroCompleto: registroCompleto ?? this.registroCompleto,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Datos personales del formulario de registro o del perfil pendiente.
class RegistrationData {
  const RegistrationData({
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.fechaNacimiento,
    required this.telefono,
    required this.correo,
  });

  final String nombre;
  final String apellido;
  final String dni;
  final DateTime fechaNacimiento;
  final String telefono;
  final String correo;
}
