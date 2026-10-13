import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyectoflutter/core/utils/app_exception.dart';
import 'package:proyectoflutter/providers/auth_provider.dart';

import 'helpers.dart';

void main() {
  group('Control de acceso', () {
    test('sin sesión → login', () async {
      final p = TestBackend().createProvider();
      await settleProvider(p);
      expect(p.status, AuthStatus.unauthenticated);
      expect(p.profile, isNull);
    });

    test('correo sin verificar → no accede al dashboard', () async {
      final b = TestBackend(
        user: MockUser(uid: 'u1', email: 'ana@correo.com', isEmailVerified: false),
      );
      await b.seedProfile('u1', registroCompleto: false);
      final p = b.createProvider();
      await settleProvider(p);
      expect(p.status, AuthStatus.pendingVerification);
    });

    test('verificado pero registro incompleto → crear contraseña', () async {
      final b = TestBackend(
        user: MockUser(uid: 'u1', email: 'ana@correo.com'),
      );
      await b.seedProfile('u1', registroCompleto: false);
      final p = b.createProvider();
      await settleProvider(p);
      expect(p.status, AuthStatus.pendingPassword);
    });

    test('verificado y completo → dashboard con perfil', () async {
      final b = TestBackend(
        user: MockUser(uid: 'u1', email: 'ana@correo.com'),
      );
      await b.seedProfile('u1', registroCompleto: true);
      final p = b.createProvider();
      await settleProvider(p);
      expect(p.status, AuthStatus.authenticated);
      expect(p.profile?.primerNombre, 'Ana');
    });

    test('cuenta sin perfil → cierra sesión con aviso', () async {
      final b = TestBackend(
        user: MockUser(uid: 'u1', email: 'ana@correo.com'),
      );
      final p = b.createProvider();
      await settleProvider(p);
      expect(p.status, AuthStatus.unauthenticated);
      expect(p.takeFlash()?.type, FlashType.error);
      expect(b.auth.currentUser, isNull);
    });

    test('cerrar sesión limpia el perfil en memoria', () async {
      final b = TestBackend(
        user: MockUser(uid: 'u1', email: 'ana@correo.com'),
      );
      await b.seedProfile('u1', registroCompleto: true);
      final p = b.createProvider();
      await settleProvider(p);
      await p.signOut();
      expect(p.status, AuthStatus.unauthenticated);
      expect(p.profile, isNull);
      expect(b.auth.currentUser, isNull);
    });
  });

  group('Registro', () {
    test('crea perfil pendiente sin contraseña y pide verificación', () async {
      final b = TestBackend(verifyEmailAutomatically: false);
      final p = b.createProvider();
      await settleProvider(p);

      await p.startRegistration(sampleRegistration());

      expect(p.status, AuthStatus.pendingVerification);
      final uid = b.auth.currentUser!.uid;
      final doc = await b.db.collection('users').doc(uid).get();
      expect(doc.data()!['registroCompleto'], false);
      expect(doc.data()!.containsKey('password'), isFalse);
      final dni = await b.db.collection('dnis').doc('87654321').get();
      expect(dni.data(), {'uid': uid});
      expect(p.resendCooldown, greaterThan(0));
    });

    test('sin verificar no avanza a la contraseña', () async {
      final b = TestBackend(verifyEmailAutomatically: false);
      final p = b.createProvider();
      await settleProvider(p);
      await p.startRegistration(sampleRegistration());

      expect(await p.checkEmailVerified(), isFalse);
      expect(p.status, AuthStatus.pendingVerification);
      await expectLater(
        p.completeRegistration('abcd1234'),
        throwsA(isA<AppException>()),
      );
      final uid = b.auth.currentUser!.uid;
      final doc = await b.db.collection('users').doc(uid).get();
      expect(doc.data()!['registroCompleto'], false);
    });

    test('reenvío respeta el tiempo de espera', () async {
      final b = TestBackend(verifyEmailAutomatically: false);
      final p = b.createProvider();
      await settleProvider(p);
      await p.startRegistration(sampleRegistration());
      await expectLater(p.resendVerification(), throwsA(isA<AppException>()));
    });

    test('flujo completo: verificar → contraseña → login', () async {
      final b = TestBackend();
      final p = b.createProvider();
      await settleProvider(p);
      await p.startRegistration(sampleRegistration());
      final uid = b.auth.currentUser!.uid;

      expect(await p.checkEmailVerified(), isTrue);
      expect(p.status, AuthStatus.pendingPassword);

      await p.completeRegistration('abcd1234');
      expect(p.status, AuthStatus.unauthenticated);
      expect(p.takeFlash()?.type, FlashType.success);
      expect(p.lastEmail, 'nuevo@correo.com');
      final doc = await b.db.collection('users').doc(uid).get();
      expect(doc.data()!['registroCompleto'], true);

      await p.signIn(email: 'nuevo@correo.com', password: 'abcd1234');
      expect(p.status, AuthStatus.authenticated);
      expect(p.profile?.nombre, 'Luis');
    });

    test('cancelar elimina perfil y reserva del DNI', () async {
      final b = TestBackend(verifyEmailAutomatically: false);
      final p = b.createProvider();
      await settleProvider(p);
      await p.startRegistration(sampleRegistration());
      final uid = b.auth.currentUser!.uid;

      await p.cancelRegistration();

      expect(p.status, AuthStatus.unauthenticated);
      expect((await b.db.collection('users').doc(uid).get()).exists, isFalse);
      expect(
        (await b.db.collection('dnis').doc('87654321').get()).exists,
        isFalse,
      );
    });
  });
}
