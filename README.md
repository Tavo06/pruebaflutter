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
| Login | Validaciones, mostrar/ocultar contraseña, carga sin envíos repetidos, «Mantener sesión iniciada» (solo web), panel de bienvenida verde oliva en escritorio, «Continuar con Google» |
| Registro (modal) | Nombre, apellido, DNI (8 dígitos), fecha de nacimiento (selector, `dd/MM/yyyy`), **número de teléfono (9 dígitos)**, correo. Errores junto a cada campo. Indicador de progreso. «Continuar con Google» |
| Google Sign-In | Mismo flujo desde login y registro. Web: popup de Firebase · Android: `google_sign_in` · Windows: OAuth de escritorio (requiere configuración, ver abajo). Perfil inicial sin datos inventados y pantalla «Completa tu perfil» |
| Verificación | Enlace real de Firebase, comprobación con `reload()`, reenvío con cuenta regresiva de 60 s, cancelación segura |
| Contraseña | Solo tras verificar; requisitos en vivo, indicador de seguridad, confirmación |
| Recuperación | Modal con `sendPasswordResetEmail`; mensaje que no revela si el correo existe |
| Dashboard | Barra lateral (escritorio), barra compacta (tableta), navegación inferior (móvil); bienvenida con el nombre real, cambio rápido de tema y un «Espacio de trabajo» vacío listo para el ejercicio (sin datos ficticios) |
| Perfil | «Mi perfil» (resumen) y «Mis datos» (editar nombre, apellido y teléfono). Los perfiles antiguos sin teléfono funcionan y muestran un aviso para completarlo |
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

## Acceso con Google

Los botones «Continuar con Google» del login y del registro llaman al mismo
`AuthProvider.signInWithGoogle()` → `AuthService.signInWithGoogle()`, que
delega la obtención de la credencial en `lib/services/google/` según la
plataforma:

| Plataforma | Mecanismo | Estado |
|---|---|---|
| Web | `FirebaseAuth.signInWithPopup(GoogleAuthProvider())` | Implementado y compilado. Requiere habilitar Google en Firebase |
| Android | `google_sign_in` 7 (Credential Manager) → `signInWithCredential` | Implementado y compilado. Requiere Google habilitado + SHA-1 + `google-services.json` actualizado |
| Windows | OAuth 2.0 para apps instaladas (navegador del sistema + loopback `127.0.0.1` + PKCE S256) → `signInWithCredential` | Implementado y compilado. Requiere un cliente OAuth de escritorio (pasos abajo). Sin él, el botón explica la limitación |

El SDK de Firebase para escritorio no implementa `signInWithPopup` ni
`signInWithProvider`, y `google_sign_in` no tiene versión para Windows; por eso
Windows usa su propio flujo. Ninguna plataforma simula un acceso: si falta la
configuración, se muestra un mensaje claro.

**Comportamiento:**
1. Se abre el selector oficial de cuenta de Google.
2. Firebase autentica con el proveedor `google.com` y se obtiene el UID.
3. Si existe `users/{uid}` se usa; si no, se crea un perfil inicial solo con
   nombre y correo del proveedor (sin DNI, fecha ni teléfono inventados).
4. Mientras falten DNI, fecha y teléfono el estado es `pendingProfile` y se
   muestra «Completa tu perfil». Al guardarlos (lote atómico con la reserva del
   DNI) se marca `registroCompleto: true` y se entra al dashboard.
5. Si Google no confirma la verificación del correo, no se crea el perfil.
   No se envía un segundo correo de verificación a cuentas ya verificadas.
6. Cancelar el selector no muestra errores ni bloquea la interfaz.

**Cuentas existentes con el mismo correo.** Con la opción por defecto de
Firebase («una cuenta por correo»), si el correo ya tiene una cuenta de
correo/contraseña **verificada**, Firebase vincula Google a esa misma cuenta
(mismo UID), así que se reutiliza su perfil y nunca se duplica. Si Firebase
responde `account-exists-with-different-credential`, la app no reemplaza ni
vincula nada automáticamente: indica al usuario que entre con su correo y
contraseña. (Comportamiento documentado por Firebase; confírmalo en las pruebas
reales.) Si la cuenta de correo aún no estaba verificada, Firebase la asocia a
la identidad de Google; su perfil pendiente (con DNI) sigue el flujo normal de
«Crea tu contraseña».

### Estado de la configuración de Google

> Comprobado el 15/10/2026 contra `parcialflutter-b50cf`:
> - Proveedor Google: **habilitado** (`createAuthUri` devuelve `authUri`).
> - Android: huellas SHA-1 y SHA-256 de depuración **registradas** con
>   `firebase apps:android:sha:create`; `google-services.json` **actualizado**
>   (incluye clientes OAuth Android y web) y la build genera
>   `default_web_client_id`.
> - Dominios autorizados: solo `parcialflutter-b50cf.firebaseapp.com` y
>   `parcialflutter-b50cf.web.app`. **Falta `localhost`** (paso 3).
> - Windows: sin cliente OAuth de escritorio (paso 4).

1. **Proveedor Google** (hecho): Authentication › Sign-in method › Google.
2. **Android** (hecho para la clave de depuración). Huellas del
   keystore de **depuración** de este equipo
   (`%USERPROFILE%\.android\debug.keystore`, leídas con `keytool`):
   - SHA-1: `8E:07:C6:10:44:6A:80:58:29:BF:62:26:34:68:08:6D:47:FB:EB:62`
   - SHA-256: `A5:CE:B5:7E:48:6E:3C:C4:28:E9:3B:15:EC:81:2C:9F:B1:FC:67:2E:E1:8C:34:E5:0B:B9:DB:02:D9:CB:CD:E6`

   Para una versión firmada de publicación hay que añadir también las huellas
   de ese keystore (o las de Play App Signing). Después **descarga de nuevo
   `google-services.json`** (o ejecuta `flutterfire configure`): debe incluir
   un `oauth_client` con `client_type: 3`, del que el plugin genera
   `default_web_client_id`.
3. **Web (pendiente):** Authentication › Settings › Authorized domains ›
   Add domain › `localhost`. Sin él, el popup de Google falla en desarrollo con
   «Este dominio no está autorizado…». Si publicas la app en otro dominio,
   añádelo también. El navegador debe permitir ventanas emergentes.
4. **Windows:** Google Cloud Console (mismo proyecto) › APIs y servicios ›
   Credenciales › Crear credenciales › ID de cliente de OAuth › **Aplicación de
   escritorio**. Ejecuta o compila con:

   ```bash
   flutter run -d windows \
     --dart-define=GOOGLE_DESKTOP_CLIENT_ID=<id>.apps.googleusercontent.com \
     --dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=<secreto>
   ```

   Google trata el secreto de un cliente de escritorio como no confidencial
   (va dentro de la app; la seguridad la aportan PKCE y el loopback). Aun así
   no se guarda en el código ni en el repositorio. Si la pantalla de
   consentimiento está en modo «Prueba», añade tus cuentas como usuarios de
   prueba.
5. Opcional (Android): si no quieres depender de `google-services.json`, pasa
   el ID del «Web client» con `--dart-define=GOOGLE_SERVER_CLIENT_ID=<id>`.

## Diseño

Paleta centralizada en `lib/core/theme/app_colors.dart`; las pantallas solo
usan `Theme.of(context).colorScheme` y `context.palette` (`app_theme.dart`),
por lo que el tema claro y el oscuro cambian sin tocar las vistas.

| Uso | Claro | Oscuro |
|---|---|---|
| Verde oliva principal | `#687447` | `#A9B57F` |
| Verde oliva oscuro (barra lateral, panel del login) | `#414B2C` | `#10130D` |
| Verde oliva suave (rellenos, avatar, selección) | `#E7EBD9` | `#353C25` |
| Acento terracota (detalles, nunca errores) | `#C87955` | `#E09A7A` |
| Fondo / superficie | `#F7F8F3` / `#FFFFFF` | `#151812` / `#1E221A` |
| Texto principal / secundario | `#25291F` / `#74786C` | `#E8EBE0` / `#A4A896` |
| Bordes | `#E0E4D8` | `#343A2C` |
| Éxito / error / advertencia | `#2E7D55` / `#C64545` / `#B7791F` | `#5DBB8A` / `#E57A7A` / `#DDA54A` |

Botones sólidos sin degradados, bordes de 10–16 px, sombras muy suaves y
tarjetas con borde fino. El terracota se usa solo en detalles (punto del logo,
indicador del menú, línea de bienvenida, icono de «Crea tu contraseña»).

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
│   └── google/               Credencial de Google por plataforma (web, android, windows)
├── providers/                auth_provider (máquina de estados), theme_provider
├── screens/
│   ├── auth/                 login, register_modal, verify_email,
│   │                         create_password_modal, forgot_password_modal,
│   │                         complete_profile_screen (perfil de Google)
│   ├── home/                 home_screen (estructura), exercise_module (reemplazable)
│   ├── profile/              profile_screen, my_data_screen
│   └── settings/             settings_screen
├── widgets/                  Componentes reutilizables
└── exercises/                Código propio de cada ejercicio
```

Estados de acceso (`AuthStatus`): `initializing` → `unauthenticated` (login) |
`pendingVerification` / `pendingPassword` (verificación) | `pendingProfile`
(cuenta de Google sin datos personales) | `authenticated` (dashboard). Cualquier ruta pasa por `AuthGate`, y al cambiar el estado se
cierran todos los modales y rutas apiladas: tras cerrar sesión, «atrás» no
vuelve al dashboard.

## Dependencias añadidas

`firebase_core`, `firebase_auth`, `cloud_firestore`, `provider`,
`shared_preferences` (solo tema y «mantener sesión»), `intl`,
`flutter_localizations`, `google_sign_in` (selector oficial en Android) y
`crypto` (PKCE S256 del flujo de Windows; ya era dependencia transitiva). Para pruebas: `firebase_auth_mocks`,
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
- `users/{uid}`: solo el dueño lee/escribe; sin listados; `hasOnly` impide
  campos no previstos (p. ej. contraseñas); correo, `uid` y `createdAt`
  inmutables; `registroCompleto` solo pasa a `true` con el correo verificado y
  nunca vuelve a `false`; solo se borran registros incompletos.
- Alta por correo (`sign_in_provider == password`): perfil completo con
  teléfono `^[0-9]{9}$` y reserva del DNI en el mismo lote.
- Alta con Google (`sign_in_provider == google.com`, correo verificado): solo
  `uid`, nombre, apellido, correo, fechas y `registroCompleto: false`.
  DNI y fecha se fijan una única vez, junto con el teléfono y la reserva del
  DNI, al completar el perfil; después no se pueden cambiar.
- `telefono` se valida en cada escritura; los documentos antiguos sin ese
  campo siguen siendo legibles y pueden añadirlo.
- `dnis/{dni}`: se reserva en el mismo lote que el perfil; un DNI existente no
  puede reservarse de nuevo (seguro ante concurrencia).
- Todo lo demás: denegado.

> Reglas **desplegadas** el 15/10/2026 con
> `firebase deploy --only firestore:rules --project parcialflutter-b50cf`
> tras pasar las 35 comprobaciones del emulador. Si cambias las reglas,
> repite `npm test` en `tools/firestore_rules_test` antes de desplegar.

Pruebas de reglas (emulador local, no toca el proyecto real; necesita Java):

```bash
cd tools/firestore_rules_test
npm install
npm test        # 35 comprobaciones
```

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

- `test/validators_test.dart`: validadores (incluido el teléfono).
- `test/user_profile_test.dart`: lectura de perfiles nuevos, antiguos sin
  teléfono y perfiles iniciales de Google.
- `test/auth_provider_test.dart`: control de acceso, registro por correo,
  Google (alta, perfil pendiente, cancelación, errores) y guardado del
  teléfono, con dobles de Firebase y de Google (no sustituyen pruebas reales).
- `test/widgets_test.dart`: login, modales, botón de Google, teléfono, perfil
  pendiente, rutas protegidas, dashboard vacío, cierre de sesión y diseño en
  320, 390, 600, 768, 1024, 1440 y 1920 px.

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
