import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyectoflutter/providers/auth_provider.dart';
import 'package:proyectoflutter/screens/auth/create_password_modal.dart';
import 'package:proyectoflutter/screens/auth/forgot_password_modal.dart';
import 'package:proyectoflutter/screens/auth/register_modal.dart';

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
      expect(find.text('Organiza tu trabajo\ncon fluidez.'), findsOneWidget);
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

    testWidgets('finanzas: Inicio → Nuevo → guardar → Historial', (
      tester,
    ) async {
      await setSize(tester, const Size(390, 844));
      final b = await signedInBackend(verified: true, complete: true);
      final p = await providerFor(tester, b);
      await tester.pumpWidget(buildTestApp(p));
      await tester.pumpAndSettle();

      // Barra inferior → Nuevo.
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Nuevo'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Registrar movimiento'), findsOneWidget);

      // Guardar vacío muestra los errores de validación.
      await tester.ensureVisible(find.text('Guardar gasto'));
      await tester.tap(find.text('Guardar gasto'));
      await tester.pumpAndSettle();
      expect(find.text('Selecciona una categoría.'), findsOneWidget);
      expect(find.text('Ingresa una descripción.'), findsOneWidget);
      expect(find.text('Ingresa el monto.'), findsOneWidget);

      // Completar el formulario.
      await tester.ensureVisible(find.text('Selecciona una categoría'));
      await tester.tap(find.text('Selecciona una categoría'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salud').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Farmacia');
      await tester.enterText(find.byType(TextFormField).at(1), '35.5');
      await tester.ensureVisible(find.text('Guardar gasto'));
      await tester.tap(find.text('Guardar gasto'));
      await tester.pumpAndSettle();

      // Navega solo al Historial y el movimiento aparece en la lista.
      expect(find.text('Todos los movimientos'), findsOneWidget);
      expect(find.text('Farmacia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Diseño adaptable sin desbordamientos', () {
    for (final size in const [
      Size(320, 640),
      Size(390, 844),
      Size(768, 1024),
      Size(1024, 700),
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
          'Nuevo movimiento',
          'Historial',
          'Resumen',
          'Mi perfil',
          'Mis datos',
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
