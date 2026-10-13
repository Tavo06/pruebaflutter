# FlowApp — Plantilla Flutter + Firebase

Plantilla multiplataforma (Android, Web y Windows) con autenticación real de
Firebase, registro con verificación de correo **antes** de crear la contraseña,
recuperación de contraseña, perfil en Cloud Firestore y un dashboard
adaptable preparado para incorporar ejercicios académicos.

- Proyecto de Firebase: `parcialflutter-b50cf`
- Flutter 3.47.2 · Dart 3.13.2

## Funcionalidades

| Área | Detalle |
|---|---|
| Login | Validaciones, mostrar/ocultar contraseña, carga sin envíos repetidos, «Mantener sesión iniciada» (solo web), panel ilustrativo en escritorio |
| Registro (modal) | Nombre, apellido, DNI (8 dígitos), fecha de nacimiento (selector, `dd/MM/yyyy`), correo. Errores junto a cada campo. Indicador de progreso |
| Verificación | Enlace real de Firebase, comprobación con `reload()`, reenvío con cuenta regresiva de 60 s, cancelación segura |
| Contraseña | Solo tras verificar; requisitos en vivo, indicador de seguridad, confirmación |
| Recuperación | Modal con `sendPasswordResetEmail`; mensaje que no revela si el correo existe |
| Dashboard | Barra lateral (escritorio), barra compacta (tableta), navegación inferior (móvil); tarjeta de bienvenida con el nombre real (dashboard vacío, listo para el ejercicio) |
| Perfil | «Mi perfil» (resumen) y «Mis datos» (editar nombre y apellido) |
| Configuración | Tema claro / oscuro / sistema guardado localmente |
| Seguridad | Reglas de Firestore de privilegio mínimo, DNI único con índice atómico, rutas privadas protegidas |

## Flujo de registro y verificación

Firebase no permite crear una cuenta de correo/contraseña sin contraseña. Para
respetar el orden **datos → verificar correo → crear contraseña** se usa esta
estrategia:

1. El usuario completa el modal de registro.
2. La app crea la cuenta con una **contraseña temporal aleatoria de 32
   caracteres** (`Random.secure()`), que solo vive en memoria durante la sesión:
   nunca se guarda, se muestra ni se registra en logs.
3. En un **lote atómico** se guardan `users/{uid}` (`registroCompleto: false`)
   y `dnis/{dni}`. Si el DNI ya existe, las reglas rechazan el lote y la cuenta
   recién creada se elimina.
4. Firebase envía el enlace real de verificación (`sendEmailVerification`). El
   enlace abre la página de acción de Firebase (`*.firebaseapp.com`), por lo que
   **no requiere enlaces profundos** en Android, web ni Windows.
5. «Ya verifiqué mi correo» consulta a Firebase (`user.reload()`); nunca se
   confía en un estado local.
6. Con el correo verificado se abre «Crea tu contraseña». Se vuelve a comprobar
   la verificación y `updatePassword()` sustituye la contraseña temporal.
7. Se marca `registroCompleto: true` (las reglas exigen `email_verified` en el
   token), se cierra la sesión y se vuelve al login.

**Retomar el registro.** Firebase conserva la sesión, así que si se cierra la
app o el navegador el usuario vuelve directamente a la verificación. Si la
sesión se pierde (otro dispositivo, datos borrados), «¿Olvidaste tu
contraseña?» le permite fijar una contraseña e iniciar sesión; la app lo lleva a
terminar el registro (verificación y contraseña definitiva) y **nunca** al
dashboard mientras esté incompleto.

**Limitaciones conocidas:**
- Cambiar la contraseña exige un inicio de sesión reciente. Si la sesión del
  registro es antigua y la app se reinició (ya no tiene la contraseña temporal),
  se pide usar «¿Olvidaste tu contraseña?».
- Los registros abandonados sin sesión no se borran solos: eso requiere Cloud
  Functions (plan Blaze, de pago). Mientras tanto, el usuario puede retomarlo
  como se indica arriba o cancelarlo desde la pantalla de verificación.

## Arquitectura

Provider + servicios. La interfaz no llama a Firebase directamente.

```
lib/
├── main.dart                 Inicializa Firebase, preferencias y proveedores
├── app.dart                  MaterialApp, temas, localización es
├── firebase_options.dart     Generado por FlutterFire CLI (no editar)
├── core/
│   ├── constants/            app_constants.dart (marca), breakpoints.dart
│   ├── routes/app_router.dart AuthGate: decide la pantalla según el estado
│   ├── theme/                app_colors.dart (paleta), app_theme.dart
│   ├── utils/app_exception.dart Errores de Firebase → mensajes en español
│   └── validators/validators.dart Validadores puros + PasswordPolicy
├── models/user_profile.dart
├── services/                 firebase_service, auth_service, user_service
├── providers/                auth_provider (máquina de estados), theme_provider
├── screens/
│   ├── auth/                 login, register_modal, verify_email,
│   │                         create_password_modal, forgot_password_modal
│   ├── home/                 home_screen (estructura), exercise_module (reemplazable)
│   ├── profile/              profile_screen, my_data_screen
│   └── settings/             settings_screen
├── widgets/                  Componentes reutilizables
└── exercises/                Código propio de cada ejercicio
```

Estados de acceso (`AuthStatus`): `initializing` → `unauthenticated` (login) |
`pendingVerification` / `pendingPassword` (verificación) | `authenticated`
(dashboard). Cualquier ruta pasa por `AuthGate`, y al cambiar el estado se
cierran todos los modales y rutas apiladas: tras cerrar sesión, «atrás» no
vuelve al dashboard.

## Dependencias añadidas

`firebase_core`, `firebase_auth`, `cloud_firestore`, `provider`,
`shared_preferences` (solo tema y «mantener sesión»), `intl`,
`flutter_localizations`. Para pruebas: `firebase_auth_mocks`,
`fake_cloud_firestore`.

## Configuración de Firebase (ya aplicada)

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=parcialflutter-b50cf --platforms=android,web,windows
firebase deploy --only auth             # habilita correo/contraseña (firebase.json)
firebase deploy --only firestore:rules  # publica firestore.rules
```

- Apps registradas: Android `com.example.proyectoflutter`, Web y Windows.
- Firestore: base `(default)` en **nam5**.
- Para producción conviene cambiar `applicationId` en
  `android/app/build.gradle.kts` y volver a ejecutar `flutterfire configure`.
- Opcional (Console → Authentication → Templates): traducir las plantillas de
  correo. La app ya pide los correos en español con `setLanguageCode('es')`.

## Reglas de Firestore

Ver `firestore.rules` (documentado). Resumen:
- `users/{uid}`: solo el dueño lee/escribe; sin listados; campos y tipos
  validados; DNI, correo y fechas inmutables; `registroCompleto` solo pasa a
  `true` con el correo verificado; solo se borran registros incompletos.
- `dnis/{dni}`: se reserva en el mismo lote que el perfil; un DNI existente no
  puede reservarse de nuevo (seguro ante concurrencia).
- Todo lo demás: denegado.

## Ejecutar

```bash
flutter pub get
flutter run -d chrome            # Web
flutter run -d windows           # Windows
flutter run -d <id-android>      # Android (flutter devices para ver el id)
```

Compilaciones: `flutter build web`, `flutter build windows`,
`flutter build apk`.

## Pruebas

```bash
flutter analyze
flutter test
```

- `test/validators_test.dart`: validadores.
- `test/auth_provider_test.dart`: control de acceso y flujo de registro con
  dobles de Firebase (no sustituyen pruebas reales).
- `test/widgets_test.dart`: login, modales, rutas protegidas, cierre de sesión
  y diseño en 320–1920 px.

## Cómo utilizar esta plantilla para un nuevo ejercicio

**Puedes modificar:**
- `lib/screens/home/exercise_module.dart`: punto de entrada del ejercicio.
- `lib/guia/practica.dart`: guía comentada (nombre, icono, colores, CRUD, roles…).
- `lib/exercises/<nombre>/`: modelos, servicios, widgets y páginas del
  ejercicio (ver `lib/exercises/README.md`).
- `lib/core/constants/app_constants.dart` y `lib/core/theme/app_colors.dart`:
  nombre y colores de la marca.
- `HomeSection` en `lib/screens/home/home_screen.dart`: si el ejercicio
  necesita una sección propia en el menú.
- `firestore.rules`: añade reglas para las colecciones del ejercicio y
  despliégalas con `firebase deploy --only firestore:rules`.

**Debe permanecer intacto:**
- `lib/services/auth_service.dart`, `lib/services/user_service.dart`,
  `lib/providers/auth_provider.dart`, `lib/core/routes/app_router.dart` y
  `lib/screens/auth/`: el sistema de autenticación.
- Las reglas de `users` y `dnis` en `firestore.rules`.
- `lib/firebase_options.dart`, `android/app/google-services.json` y
  `firebase.json`: los regenera `flutterfire configure`.

Pasos:
1. Crea `lib/exercises/<nombre>/` con el código del ejercicio.
2. Muestra su vista desde `ExerciseModule`.
3. Si guarda datos, crea su servicio y sus reglas de Firestore.
4. Ejecuta `flutter analyze` y `flutter test`, y añade pruebas del ejercicio.
