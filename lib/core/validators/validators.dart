import '../constants/app_constants.dart';

/// Validadores puros e independientes de la interfaz.
///
/// Devuelven `null` si el valor es válido o un mensaje en español si no.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\.[A-Za-z]{2,}$",
  );

  /// Palabras con letras (incluye tildes, ñ y ü) separadas por un espacio,
  /// guion o apóstrofo. Admite nombres y apellidos compuestos.
  static final RegExp _nameRegex = RegExp(
    r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñÀÈÌÒÙàèìòùÇç]+(?:[ '\-][A-Za-zÁÉÍÓÚÜÑáéíóúüñÀÈÌÒÙàèìòùÇç]+)*$",
  );

  static final RegExp _dniRegex = RegExp(r'^\d{8}$');

  /// Elimina espacios al inicio/final y colapsa los espacios intermedios.
  static String normalizeName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Elimina espacios y convierte el correo a minúsculas.
  static String normalizeEmail(String value) => value.trim().toLowerCase();

  static String? email(String? value) {
    final v = normalizeEmail(value ?? '');
    if (v.isEmpty) return 'Ingresa tu correo electrónico.';
    if (v.length > 254 || !_emailRegex.hasMatch(v)) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña.';
    return null;
  }

  static String? firstName(String? value) => _personName(value, 'nombre');

  static String? lastName(String? value) => _personName(value, 'apellido');

  static String? _personName(String? value, String label) {
    final v = normalizeName(value ?? '');
    if (v.isEmpty) return 'Ingresa tu $label.';
    if (v.length < 2) return 'El $label debe tener al menos 2 letras.';
    if (v.length > AppConstants.maxNameLength) {
      return 'El $label no puede superar '
          '${AppConstants.maxNameLength} caracteres.';
    }
    if (RegExp(r'\d').hasMatch(v)) {
      return 'El $label no puede contener números.';
    }
    if (!_nameRegex.hasMatch(v)) {
      return 'El $label solo puede contener letras, espacios, '
          'guiones o apóstrofos.';
    }
    return null;
  }

  static String? dni(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Ingresa tu DNI.';
    if (!RegExp(r'^\d+$').hasMatch(v)) {
      return 'El DNI solo puede contener números.';
    }
    if (!_dniRegex.hasMatch(v)) {
      return 'El DNI debe tener exactamente ${AppConstants.dniLength} dígitos.';
    }
    return null;
  }

  /// Valida la fecha de nacimiento. [now] permite fijar la fecha en pruebas.
  static String? birthDate(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Selecciona tu fecha de nacimiento.';
    final today = _dateOnly(now ?? DateTime.now());
    final date = _dateOnly(value);
    if (date.isAfter(today)) {
      return 'La fecha de nacimiento no puede ser futura.';
    }
    if (date.isBefore(DateTime(1900))) {
      return 'Ingresa una fecha de nacimiento válida.';
    }
    return null;
  }

  /// Interpreta una fecha en formato `dd/MM/yyyy` y comprueba que exista
  /// (por ejemplo, rechaza `31/02/2000`). Devuelve `null` si no es válida.
  static DateTime? parseDate(String value) {
    final match = RegExp(
      r'^(\d{2})/(\d{2})/(\d{4})$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static String? password(String? value, {PasswordPolicy? policy}) {
    final p = policy ?? PasswordPolicy.standard;
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa una contraseña.';
    final failed = p.evaluate(v).where((r) => !r.met).toList();
    if (failed.isEmpty) return null;
    return 'La contraseña debe cumplir: ${failed.first.label.toLowerCase()}.';
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña.';
    if (value != original) return 'Las contraseñas no coinciden.';
    return null;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Requisito individual de contraseña y su resultado.
class PasswordRequirement {
  const PasswordRequirement(this.label, this.met);

  final String label;
  final bool met;
}

enum PasswordStrength { empty, weak, medium, strong }

/// Reglas configurables de contraseña.
class PasswordPolicy {
  const PasswordPolicy({
    this.minLength = 8,
    this.requireLetter = true,
    this.requireDigit = true,
    this.requireUppercase = false,
    this.requireSymbol = false,
  });

  /// Política usada por defecto en la aplicación.
  static const standard = PasswordPolicy();

  final int minLength;
  final bool requireLetter;
  final bool requireDigit;
  final bool requireUppercase;
  final bool requireSymbol;

  List<PasswordRequirement> evaluate(String value) => [
    PasswordRequirement(
      'Mínimo $minLength caracteres',
      value.length >= minLength,
    ),
    if (requireLetter)
      PasswordRequirement(
        'Al menos una letra',
        RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(value),
      ),
    if (requireDigit)
      PasswordRequirement('Al menos un número', RegExp(r'\d').hasMatch(value)),
    if (requireUppercase)
      PasswordRequirement(
        'Al menos una mayúscula',
        RegExp(r'[A-ZÁÉÍÓÚÜÑ]').hasMatch(value),
      ),
    if (requireSymbol)
      PasswordRequirement(
        'Al menos un símbolo',
        RegExp(r'[^A-Za-z0-9\s]').hasMatch(value),
      ),
  ];

  PasswordStrength strength(String value) {
    if (value.isEmpty) return PasswordStrength.empty;
    final allMet = evaluate(value).every((r) => r.met);
    if (!allMet) return PasswordStrength.weak;
    var score = 0;
    if (value.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score >= 2 ? PasswordStrength.strong : PasswordStrength.medium;
  }
}
