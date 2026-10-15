import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyectoflutter/providers/auth_provider.dart';
import 'package:proyectoflutter/screens/auth/complete_profile_screen.dart';
import 'package:proyectoflutter/screens/auth/create_password_modal.dart';
import 'package:proyectoflutter/screens/auth/forgot_password_modal.dart';
import 'package:proyectoflutter/screens/auth/register_modal.dart';
import 'package:proyectoflutter/screens/home/home_screen.dart';
import 'package:proyectoflutter/widgets/status_banner.dart';

import 'helpers.dart';

Future<void> setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Crea el proveedor fuera del reloj simulado y espera su estado inicial.
Future<AuthProvider> providerFor(WidgetTester tester, TestBackend b) async {
  late AuthProvider p;
  await tester.runAsync(() async {
    p = b.createProvider();
    await settleProvider(p);
  });
  return p;
}

Future<TestBackend> signedInBackend({
  required bool verified,
  required bool complete,
}) async {
  final b = TestBackend(
    user: MockUser(
      uid: 'u1',
      email: 'ana@correo.com',
      isEmailVerified: verified,
    ),
  );
  await b.seedProfile('u1', registroCompleto: complete);
  return b;
}

void main() {
  group('Login', () {
    testWidgets('valida campos obligatorios', (tester) async {
      await setSize(tester, const Size(400, 900));
      final p = await providerFor(tester, TestBackend());
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsWidgets);
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('login_email')), 'malo');
      await tester.pumpAndSettle();
      expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
    });

    testWidgets('mostrar/ocultar contraseña', (tester) async {
      await setSize(tester, const Size(400, 900));
      final p = await providerFor(tester, TestBackend());
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      EditableText field() => tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('login_password')),
          matching: find.byType(EditableText),
        ),
      );
      expect(field().obscureText, isTrue);
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(field().obscureText, isFalse);
    });

    testWidgets('«Crear cuenta» abre el registro como modal', (tester) async {
      await setSize(tester, const Size(1280, 900));
      final p = await providerFor(tester, TestBackend());
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_register')));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterModal), findsOneWidget);
      // El login sigue debajo del modal.
      expect(find.byKey(const Key('login_submit')), findsOneWidget);
    });

    testWidgets('diseño a dos paneles en escritorio', (tester) async {
      await setSize(tester, const Size(1400, 900));
      final p = await providerFor(tester, TestBackend());
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();
      expect(find.text('Te damos la\nbienvenida.'), findsOneWidget);
    });

    testWidgets('botón de Google y separador en el login', (tester) async {
      await setSize(tester, const Size(400, 900));
      final p = await providerFor(tester, TestBackend());
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('o continúa con tu correo'), findsOneWidget);
    });

    testWidgets('cancelar Google no muestra error ni bloquea la interfaz', (
      tester,
    ) async {
      await setSize(tester, const Size(400, 900));
      final b = TestBackend(
        google: FakeGoogleDelegate(outcome: GoogleOutcome.cancel),
      );
      final p = await providerFor(tester, b);
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('google_sign_in')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(b.google.calls, 1);
      expect(find.byType(StatusBanner), findsNothing);
      final button = tester.widget<OutlinedButton>(
        find.byKey(const Key('google_sign_in')),
      );
      expect(button.onPressed, isNotNull);
      expect(find.byKey(const Key('login_submit')), findsOneWidget);
    });

    testWidgets('error de configuración de Google se muestra al usuario', (
      tester,
    ) async {
      await setSize(tester, const Size(400, 900));
      final b = TestBackend(
        google: FakeGoogleDelegate(
          outcome: GoogleOutcome.error,
          errorCode: 'operation-not-allowed',
        ),
      );
      final p = await providerFor(tester, b);
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('google_sign_in')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Google no está habilitado'),
        findsOneWidget,
      );
    });

    testWidgets('Google desde el registro lleva a «Completa tu perfil»', (
      tester,
    ) async {
      await setSize(tester, const Size(1280, 900));
      final b = TestBackend(user: googleUser(), signedIn: false);
      final p = await providerFor(tester, b);
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_register')));
      await tester.pumpAndSettle();
      final inModal = find.descendant(
        of: find.byType(RegisterModal),
        matching: find.byKey(const Key('google_sign_in')),
      );
      expect(inModal, findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(inModal);
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();

      expect(find.byType(RegisterModal), findsNothing);
      expect(find.byType(CompleteProfileScreen), findsOneWidget);
      expect(find.text('¡Hola, Lucía!'), findsNothing);
      // Los datos de Google se proponen, pero el DNI y el teléfono no.
      expect(find.text('Lucía'), findsOneWidget);
      final phone = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('profile_telefono')),
          matching: find.byType(EditableText),
        ),
      );
      expect(phone.controller.text, isEmpty);
    });
  });

  group('Perfil pendiente de Google', () {
    testWidgets('exige DNI, fecha y teléfono válidos', (tester) async {
      await setSize(tester, const Size(800, 1100));
      final b = TestBackend(user: googleUser(), signedIn: false);
      final p = await providerFor(tester, b);
      await tester.runAsync(() => p.signInWithGoogle());
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('profile_submit')));
      await tester.tap(find.byKey(const Key('profile_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa tu DNI.'), findsOneWidget);
      expect(find.text('Selecciona tu fecha de nacimiento.'), findsOneWidget);
      expect(find.text('Ingresa tu número de teléfono.'), findsOneWidget);
      expect(p.status, AuthStatus.pendingProfile);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Registro (modal)', () {
    testWidgets('muestra errores junto a cada campo', (tester) async {
      await setSize(tester, const Size(800, 1000));
      final p = await providerFor(tester, TestBackend());
      await tester.pumpWidget(wrapWidget(p, const RegisterModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('register_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa tu nombre.'), findsOneWidget);
      expect(find.text('Ingresa tu apellido.'), findsOneWidget);
      expect(find.text('Ingresa tu DNI.'), findsOneWidget);
      expect(find.text('Selecciona tu fecha de nacimiento.'), findsOneWidget);
      expect(find.text('Ingresa tu número de teléfono.'), findsOneWidget);
      expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('register_nombre')), 'Juan2');
      await tester.enterText(find.byKey(const Key('register_dni')), '12ab34');
      await tester.pumpAndSettle();
      expect(find.text('El nombre no puede contener números.'), findsOneWidget);
      // Solo se aceptan dígitos: «12ab34» queda como «1234».
      expect(
        find.text('El DNI debe tener exactamente 8 dígitos.'),
        findsOneWidget,
      );
    });

    testWidgets('el DNI se limita a 8 dígitos', (tester) async {
      await setSize(tester, const Size(800, 1000));
      final p = await providerFor(tester, TestBackend());
      await tester.pumpWidget(wrapWidget(p, const RegisterModal()));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('register_dni')),
        '1234567890',
      );
      await tester.pump();
      final field = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('register_dni')),
          matching: find.byType(EditableText),
        ),
      );
      expect(field.controller.text, '12345678');
    });

    testWidgets('teléfono: solo dígitos, máximo 9 y teclado numérico', (
      tester,
    ) async {
      await setSize(tester, const Size(800, 1100));
      final p = await providerFor(tester, TestBackend());
      await tester.pumpWidget(wrapWidget(p, const RegisterModal()));
      await tester.pumpAndSettle();

      final phone = find.byKey(const Key('register_telefono'));
      EditableText field() => tester.widget<EditableText>(
        find.descendant(of: phone, matching: find.byType(EditableText)),
      );
      expect(field().keyboardType, TextInputType.number);

      // Letras, espacios, guiones y símbolos se descartan al escribir.
      await tester.enterText(phone, '98a7 6-5+4#');
      await tester.pumpAndSettle();
      expect(field().controller.text, '987654');
      expect(
        find.text('El número de teléfono debe tener exactamente 9 dígitos.'),
        findsOneWidget,
      );

      // Ocho dígitos: error.
      await tester.enterText(phone, '98765432');
      await tester.pumpAndSettle();
      expect(
        find.text('El número de teléfono debe tener exactamente 9 dígitos.'),
        findsOneWidget,
      );

      // Diez dígitos: se limita a nueve y es válido.
      await tester.enterText(phone, '9876543210');
      await tester.pumpAndSettle();
      expect(field().controller.text, '987654321');
      expect(find.textContaining('número de teléfono'), findsNothing);
    });

    testWidgets('incluye el botón de Google y el separador', (tester) async {
      await setSize(tester, const Size(800, 1100));
      final p = await providerFor(tester, TestBackend());
      await tester.pumpWidget(wrapWidget(p, const RegisterModal()));
      await tester.pumpAndSettle();
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('o continúa con tu correo'), findsOneWidget);
    });

    testWidgets('la fecha se elige con el selector en dd/MM/yyyy', (
      tester,
    ) async {
      await setSize(tester, const Size(800, 1000));
      final p = await providerFor(tester, TestBackend());
      await tester.pumpWidget(wrapWidget(p, const RegisterModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('register_fecha')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      // Cambia al modo de texto e introduce una fecha concreta.
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.byType(TextField),
        ),
        '15/03/1999',
      );
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expect(find.text('15/03/1999'), findsOneWidget);
    });
  });

  group('Recuperar contraseña', () {
    testWidgets('valida y confirma sin revelar si la cuenta existe', (
      tester,
    ) async {
      await setSize(tester, const Size(800, 900));
      final p = await providerFor(tester, TestBackend());
      await tester.pumpWidget(wrapWidget(p, const ForgotPasswordModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('forgot_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('forgot_email')),
        'nadie@correo.com',
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('forgot_submit')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('Si existe una cuenta asociada'), findsOneWidget);
    });
  });

  group('Crear contraseña (modal)', () {
    testWidgets('requisitos, seguridad y confirmación', (tester) async {
      await setSize(tester, const Size(800, 1000));
      final p = await providerFor(tester, TestBackend());
      await tester.pumpWidget(wrapWidget(p, const CreatePasswordModal()));
      await tester.pumpAndSettle();

      expect(find.text('Seguridad: Sin contraseña'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('create_password')), 'abc');
      await tester.pumpAndSettle();
      expect(find.text('Seguridad: Débil'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('create_password')),
        'abcd1234',
      );
      await tester.enterText(
        find.byKey(const Key('create_password_confirm')),
        'abcd9999',
      );
      await tester.pumpAndSettle();
      expect(find.text('Seguridad: Aceptable'), findsOneWidget);
      await tester.tap(find.byKey(const Key('create_password_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    });
  });

  group('Rutas protegidas', () {
    testWidgets('correo sin verificar muestra la verificación, no el dashboard', (
      tester,
    ) async {
      await setSize(tester, const Size(400, 900));
      final b = await signedInBackend(verified: false, complete: false);
      final p = await providerFor(tester, b);
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      expect(find.text('Verifica tu correo electrónico'), findsOneWidget);
      expect(find.text('ana@correo.com'), findsNothing); // dentro de un TextSpan
      expect(find.textContaining('ana@correo.com', findRichText: true), findsOneWidget);
      expect(find.textContaining('Reenviar correo en'), findsNothing);
      expect(find.text('¡Hola, Ana!'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('verificado sin contraseña abre «Crea tu contraseña»', (
      tester,
    ) async {
      await setSize(tester, const Size(1280, 900));
      final b = await signedInBackend(verified: true, complete: false);
      final p = await providerFor(tester, b);
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePasswordModal), findsOneWidget);
      expect(find.text('¡Hola, Ana!'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('dashboard en escritorio y cierre de sesión', (tester) async {
      await setSize(tester, const Size(1400, 900));
      final b = await signedInBackend(verified: true, complete: true);
      final p = await providerFor(tester, b);
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      expect(find.text('¡Hola, Ana!'), findsOneWidget);
      expect(find.text('Bienvenido a tu espacio de trabajo.'), findsOneWidget);
      expect(find.byKey(const Key('sidebar_logout')), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('sidebar_logout')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login_submit')), findsOneWidget);
      expect(find.text('¡Hola, Ana!'), findsNothing);
      expect(p.profile, isNull);

      // El botón atrás no devuelve al dashboard.
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      expect(nav.canPop(), isFalse);
    });

    testWidgets('móvil usa navegación inferior', (tester) async {
      await setSize(tester, const Size(390, 844));
      final b = await signedInBackend(verified: true, complete: true);
      final p = await providerFor(tester, b);
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byKey(const Key('sidebar_logout')), findsNothing);
      // «Mis datos» no está en la barra inferior: se abre desde el menú.
      await tester.tap(find.byKey(const Key('user_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mis datos'));
      await tester.pumpAndSettle();
      expect(find.text('Datos personales'), findsOneWidget);
    });

    testWidgets('dashboard limpio: espacio de trabajo sin datos ficticios', (
      tester,
    ) async {
      await setSize(tester, const Size(1440, 900));
      final b = await signedInBackend(verified: true, complete: true);
      final p = await providerFor(tester, b);
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('workspace_placeholder')), findsOneWidget);
      expect(find.text('Espacio de trabajo'), findsOneWidget);
      expect(
        find.text('Aquí podrás implementar el ejercicio que necesites.'),
        findsOneWidget,
      );
      for (final t in ['Nuevo movimiento', 'Historial', 'Resumen', 'Saldo']) {
        expect(find.textContaining(t), findsNothing);
      }
      // Con teléfono registrado no aparece el aviso.
      expect(find.byKey(const Key('add_phone')), findsNothing);
    });

    testWidgets('perfil antiguo sin teléfono: aviso y edición en Mis datos', (
      tester,
    ) async {
      await setSize(tester, const Size(1440, 900));
      final b = TestBackend(
        user: MockUser(uid: 'u1', email: 'ana@correo.com'),
      );
      await b.seedProfile('u1', registroCompleto: true, telefono: null);
      final p = await providerFor(tester, b);
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_phone')));
      await tester.pumpAndSettle();
      expect(find.text('Datos personales'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('data_telefono')), '12345');
      await tester.pumpAndSettle();
      expect(
        find.text('El número de teléfono debe tener exactamente 9 dígitos.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('data_telefono')),
        '923456789',
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('data_save')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('Tus datos se guardaron correctamente.'), findsOneWidget);
      expect((await b.userDoc('u1'))!['telefono'], '923456789');
      expect((await b.userDoc('u1'))!['dni'], '12345678');
    });

    testWidgets('el tema se cambia desde la barra superior', (tester) async {
      await setSize(tester, const Size(1440, 900));
      final b = await signedInBackend(verified: true, complete: true);
      final p = await providerFor(tester, b);
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(find.byType(HomeScreen))).brightness,
          Brightness.light);
      await tester.tap(find.byKey(const Key('theme_toggle')));
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(find.byType(HomeScreen))).brightness,
          Brightness.dark);
    });
  });

  group('Diseño adaptable sin desbordamientos', () {
    for (final size in const [
      Size(320, 640),
      Size(390, 844),
      Size(600, 960),
      Size(768, 1024),
      Size(1024, 700),
      Size(1440, 900),
      Size(1920, 1080),
    ]) {
      testWidgets('login y secciones a ${size.width.toInt()}px', (
        tester,
      ) async {
        await setSize(tester, size);
        final b = await signedInBackend(verified: true, complete: true);
        final p = await providerFor(tester, b);
        await tester.pumpWidget(buildTestApp(p));
        await tester.pumpAndSettle();

        for (final label in [
          'Mi perfil',
          'Perfil',
          'Mis datos',
          'Datos',
          'Inicio',
        ]) {
          final target = find.text(label);
          if (target.evaluate().isNotEmpty) {
            await tester.tap(target.first);
            await tester.pumpAndSettle();
          }
        }
        // Configuración aparece como «Ajustes» en móvil.
        final settings = find.text('Configuración').evaluate().isNotEmpty
            ? find.text('Configuración')
            : find.text('Ajustes');
        if (settings.evaluate().isNotEmpty) {
          await tester.tap(settings.first);
          await tester.pumpAndSettle();
        }

        await tester.runAsync(() => p.signOut());
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('login_submit')), findsOneWidget);

        await tester.ensureVisible(find.byKey(const Key('login_register')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('login_register')));
        await tester.pumpAndSettle();
        expect(find.byType(RegisterModal), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
