import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyectoflutter/models/user_profile.dart';

void main() {
  test('lee el teléfono guardado', () {
    final p = UserProfile.fromMap({
      'uid': 'u1',
      'nombre': 'Ana',
      'apellido': 'Pérez',
      'dni': '12345678',
      'fechaNacimiento': Timestamp.fromDate(DateTime.utc(2000, 5, 1)),
      'telefono': '987654321',
      'correo': 'ana@correo.com',
      'registroCompleto': true,
    });
    expect(p.telefono, '987654321');
    expect(p.tieneTelefono, isTrue);
    expect(p.fechaNacimiento, DateTime(2000, 5, 1));
  });

  test('documento antiguo sin teléfono se lee sin errores', () {
    final p = UserProfile.fromMap({
      'uid': 'u1',
      'nombre': 'Ana',
      'apellido': 'Pérez',
      'dni': '12345678',
      'fechaNacimiento': Timestamp.fromDate(DateTime.utc(2000, 5, 1)),
      'correo': 'ana@correo.com',
      'registroCompleto': true,
    });
    expect(p.telefono, isNull);
    expect(p.tieneTelefono, isFalse);
    expect(p.tieneDatosPersonales, isTrue);
  });

  test('perfil inicial de Google sin DNI ni fecha', () {
    final p = UserProfile.fromMap({
      'uid': 'g1',
      'nombre': '',
      'apellido': '',
      'correo': 'lucia@gmail.com',
      'registroCompleto': false,
    });
    expect(p.dni, isNull);
    expect(p.fechaNacimiento, isNull);
    expect(p.tieneDatosPersonales, isFalse);
    expect(p.iniciales, 'L');
    expect(p.primerNombre, 'lucia');
  });
}
