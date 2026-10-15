import 'package:flutter_test/flutter_test.dart';
import 'package:proyectoflutter/core/validators/validators.dart';

void main() {
  group('email', () {
    test('rechaza vacío y formatos inválidos', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('   '), isNotNull);
      expect(Validators.email('sin-arroba.com'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('a b@correo.com'), isNotNull);
    });

    test('acepta correos válidos con espacios alrededor', () {
      expect(Validators.email('ana@correo.com'), isNull);
      expect(Validators.email('  Ana.Perez+1@Correo.PE  '), isNull);
    });

    test('normaliza espacios y mayúsculas', () {
      expect(Validators.normalizeEmail('  Ana@Correo.COM '), 'ana@correo.com');
    });
  });

  group('nombre y apellido', () {
    test('acepta tildes, ñ, compuestos, guiones y apóstrofos', () {
      expect(Validators.firstName('María José'), isNull);
      expect(Validators.firstName('Íñigo'), isNull);
      expect(Validators.lastName('Pérez de la Cruz'), isNull);
      expect(Validators.lastName("O'Connor"), isNull);
      expect(Validators.lastName('García-Núñez'), isNull);
      expect(Validators.firstName('  Luis   Alberto  '), isNull);
    });

    test('rechaza vacíos, números y caracteres inválidos', () {
      expect(Validators.firstName(''), isNotNull);
      expect(Validators.firstName('A'), isNotNull);
      expect(Validators.firstName('Juan2'), contains('números'));
      expect(Validators.lastName('Pérez@'), isNotNull);
      expect(Validators.lastName('--'), isNotNull);
      expect(Validators.firstName('a' * 51), isNotNull);
    });

    test('normaliza espacios', () {
      expect(Validators.normalizeName('  María   José '), 'María José');
    });
  });

  group('DNI', () {
    test('exige exactamente 8 dígitos', () {
      expect(Validators.dni('12345678'), isNull);
      expect(Validators.dni(''), isNotNull);
      expect(Validators.dni('1234567'), contains('8'));
      expect(Validators.dni('123456789'), isNotNull);
      expect(Validators.dni('1234567a'), contains('números'));
    });
  });

  group('teléfono', () {
    test('vacío', () {
      expect(Validators.phone(null), 'Ingresa tu número de teléfono.');
      expect(Validators.phone(''), 'Ingresa tu número de teléfono.');
      expect(Validators.phone('   '), 'Ingresa tu número de teléfono.');
    });

    test('ocho y diez dígitos se rechazan', () {
      expect(Validators.phone('98765432'), contains('exactamente 9'));
      expect(Validators.phone('9876543210'), contains('exactamente 9'));
    });

    test('letras, espacios, guiones y símbolos se rechazan', () {
      expect(Validators.phone('98765432a'), contains('solo puede contener'));
      expect(Validators.phone('987 654 321'), contains('solo puede contener'));
      expect(Validators.phone('987-654-321'), contains('solo puede contener'));
      expect(Validators.phone('+51987654'), contains('solo puede contener'));
      expect(Validators.phone('98765432#'), contains('solo puede contener'));
    });

    test('nueve dígitos es válido, sin exigir prefijo ni operador', () {
      expect(Validators.phone('987654321'), isNull);
      expect(Validators.phone('012345678'), isNull);
      expect(Validators.phoneRegex.pattern, r'^[0-9]{9}$');
    });
  });

  group('fecha de nacimiento', () {
    final now = DateTime(2026, 10, 13);

    test('obligatoria', () {
      expect(Validators.birthDate(null, now: now), isNotNull);
    });

    test('rechaza fechas futuras y anteriores a 1900', () {
      expect(Validators.birthDate(DateTime(2026, 10, 14), now: now), isNotNull);
      expect(Validators.birthDate(DateTime(1899, 12, 31), now: now), isNotNull);
    });

    test('acepta hoy y fechas pasadas sin edad mínima', () {
      expect(Validators.birthDate(DateTime(2026, 10, 13), now: now), isNull);
      expect(Validators.birthDate(DateTime(2000, 2, 29), now: now), isNull);
    });

    test('parseDate valida fechas reales en dd/MM/yyyy', () {
      expect(Validators.parseDate('29/02/2000'), DateTime(2000, 2, 29));
      expect(Validators.parseDate('29/02/2001'), isNull);
      expect(Validators.parseDate('31/04/2020'), isNull);
      expect(Validators.parseDate('2020-01-01'), isNull);
    });
  });

  group('contraseña', () {
    test('mínimo 8 caracteres, una letra y un número', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('abc123'), isNotNull);
      expect(Validators.password('abcdefgh'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('abcd1234'), isNull);
    });

    test('reglas adicionales configurables', () {
      const strict = PasswordPolicy(requireUppercase: true, requireSymbol: true);
      expect(Validators.password('abcd1234', policy: strict), isNotNull);
      expect(Validators.password('Abcd1234!', policy: strict), isNull);
    });

    test('confirmación idéntica', () {
      expect(Validators.confirmPassword('', 'abcd1234'), isNotNull);
      expect(Validators.confirmPassword('abcd1235', 'abcd1234'), isNotNull);
      expect(Validators.confirmPassword('abcd1234', 'abcd1234'), isNull);
    });

    test('indicador de seguridad', () {
      const p = PasswordPolicy.standard;
      expect(p.strength(''), PasswordStrength.empty);
      expect(p.strength('abc'), PasswordStrength.weak);
      expect(p.strength('abcd1234'), PasswordStrength.medium);
      expect(p.strength('Abcd1234!xyz'), PasswordStrength.strong);
    });
  });
}
