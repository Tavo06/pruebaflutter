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

    test('guarda el teléfono en el perfil de Firestore', () async {
      final b = TestBackend(verifyEmailAutomatically: false);
      final p = b.createProvider();
      await settleProvider(p);
      await p.startRegistration(sampleRegistration());
      final doc = await b.userDoc(b.auth.currentUser!.uid);
      expect(doc!['telefono'], '987654321');
      expect(p.profile?.telefono, '987654321');
    });
  });

  group('Perfil y teléfono', () {
    test('perfil antiguo sin teléfono sigue accediendo al dashboard', () async {
      final b = TestBackend(
        user: MockUser(uid: 'u1', email: 'ana@correo.com'),
      );
      await b.seedProfile('u1', registroCompleto: true, telefono: null);
      final p = b.createProvider();
      await settleProvider(p);
      expect(p.status, AuthStatus.authenticated);
      expect(p.profile?.telefono, isNull);
      expect(p.profile?.tieneTelefono, isFalse);
    });

    test('añadir el teléfono no sobrescribe los demás campos', () async {
      final b = TestBackend(
        user: MockUser(uid: 'u1', email: 'ana@correo.com'),
      );
      await b.seedProfile('u1', registroCompleto: true, telefono: null);
      final p = b.createProvider();
      await settleProvider(p);

      await p.updateProfileData(
        nombre: 'Ana María',
        apellido: 'Pérez',
        telefono: '923456789',
      );
      final doc = await b.userDoc('u1');
      expect(doc!['telefono'], '923456789');
      expect(doc['dni'], '12345678');
      expect(doc['registroCompleto'], true);
      expect(doc['correo'], 'ana@correo.com');
      expect(p.profile?.telefono, '923456789');
    });

    test('cambio parcial sin teléfono conserva el teléfono guardado', () async {
      final b = TestBackend(
        user: MockUser(uid: 'u1', email: 'ana@correo.com'),
      );
      await b.seedProfile('u1', registroCompleto: true);
      final p = b.createProvider();
      await settleProvider(p);

      await p.updateProfileData(nombre: 'Ana', apellido: 'Pérez');
      final doc = await b.userDoc('u1');
      expect(doc!['nombre'], 'Ana');
      expect(doc['telefono'], '912345678');
    });
  });

  group('Google', () {
    test('primer acceso: crea perfil inicial sin inventar datos', () async {
      final b = TestBackend(user: googleUser(), signedIn: false);
      final p = b.createProvider();
      await settleProvider(p);

      expect(await p.signInWithGoogle(), isTrue);

      expect(p.status, AuthStatus.pendingProfile);
      final doc = await b.userDoc('g1');
      expect(doc!['correo'], 'lucia@gmail.com');
      expect(doc['nombre'], 'Lucía');
      expect(doc['apellido'], 'Torres Ramos');
      expect(doc['registroCompleto'], false);
      expect(doc.containsKey('dni'), isFalse);
      expect(doc.containsKey('fechaNacimiento'), isFalse);
      expect(doc.containsKey('telefono'), isFalse);
      expect(doc.containsKey('password'), isFalse);
    });

    test('completar el perfil da acceso al dashboard', () async {
      final b = TestBackend(user: googleUser(), signedIn: false);
      final p = b.createProvider();
      await settleProvider(p);
      await p.signInWithGoogle();

      await p.completePendingProfile(sampleRegistration());

      expect(p.status, AuthStatus.authenticated);
      final doc = await b.userDoc('g1');
      expect(doc!['registroCompleto'], true);
      expect(doc['dni'], '87654321');
      expect(doc['telefono'], '987654321');
      expect(doc['fechaNacimiento'], isNotNull);
      final dni = await b.db.collection('dnis').doc('87654321').get();
      expect(dni.data(), {'uid': 'g1'});
    });

    test('el perfil pendiente se retoma al volver a abrir la app', () async {
      final b = TestBackend(user: googleUser());
      await b.db.collection('users').doc('g1').set({
        'uid': 'g1',
        'nombre': 'Lucía',
        'apellido': 'Torres',
        'correo': 'lucia@gmail.com',
        'registroCompleto': false,
      });
      final p = b.createProvider();
      await settleProvider(p);
      expect(p.status, AuthStatus.pendingProfile);
    });

    test('usuario existente: recupera su perfil sin duplicarlo', () async {
      final b = TestBackend(user: googleUser(uid: 'u1'), signedIn: false);
      await b.seedProfile(
        'u1',
        registroCompleto: true,
        email: 'lucia@gmail.com',
      );
      final p = b.createProvider();
      await settleProvider(p);

      await p.signInWithGoogle();

      expect(p.status, AuthStatus.authenticated);
      expect(p.profile?.dni, '12345678');
      expect((await b.db.collection('users').get()).docs, hasLength(1));
    });

    test('cancelar el selector no es un error ni crea datos', () async {
      final b = TestBackend(
        user: googleUser(),
        signedIn: false,
        google: FakeGoogleDelegate(outcome: GoogleOutcome.cancel),
      );
      final p = b.createProvider();
      await settleProvider(p);

      expect(await p.signInWithGoogle(), isFalse);
      expect(p.status, AuthStatus.unauthenticated);
      expect((await b.db.collection('users').get()).docs, isEmpty);
    });

    test('cuenta existente con otro proveedor: informa sin reemplazar', () async {
      final b = TestBackend(
        google: FakeGoogleDelegate(
          outcome: GoogleOutcome.error,
          errorCode: 'account-exists-with-different-credential',
        ),
      );
      final p = b.createProvider();
      await settleProvider(p);

      await expectLater(
        p.signInWithGoogle(),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('otro método de acceso'),
          ),
        ),
      );
      expect(p.status, AuthStatus.unauthenticated);
    });

    test('Google deshabilitado en Firebase: mensaje de configuración', () async {
      final b = TestBackend(
        google: FakeGoogleDelegate(
          outcome: GoogleOutcome.error,
          errorCode: 'operation-not-allowed',
        ),
      );
      final p = b.createProvider();
      await settleProvider(p);
      await expectLater(
        p.signInWithGoogle(),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('Google no está habilitado'),
          ),
        ),
      );
    });

    test('correo de Google sin verificar no crea perfil', () async {
      final b = TestBackend(
        user: googleUser(verified: false),
        signedIn: false,
        verifyEmailAutomatically: false,
      );
      final p = b.createProvider();
      await settleProvider(p);

      await p.signInWithGoogle();

      expect(p.status, AuthStatus.unauthenticated);
      expect(p.takeFlash()?.type, FlashType.error);
      expect(await b.userDoc('g1'), isNull);
    });

    test('cerrar sesión también cierra la sesión del proveedor', () async {
      final b = TestBackend(user: googleUser(), signedIn: false);
      final p = b.createProvider();
      await settleProvider(p);
      await p.signInWithGoogle();
      await p.signOut();
      expect(b.google.signOuts, 1);
      expect(p.status, AuthStatus.unauthenticated);
    });

    test('separa el nombre visible en nombre y apellido', () {
      expect(AuthProvider.splitDisplayName(null), ('', ''));
      expect(AuthProvider.splitDisplayName('Lucía'), ('Lucía', ''));
      expect(AuthProvider.splitDisplayName('Ana Pérez'), ('Ana', 'Pérez'));
      expect(
        AuthProvider.splitDisplayName('María José Pérez Díaz'),
        ('María José', 'Pérez Díaz'),
      );
    });
  });
}
