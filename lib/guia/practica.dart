// =============================================================================
//  GUÍA PRÁCTICA DE LA PLANTILLA FLOWAPP
// =============================================================================
//
//  Este archivo solo contiene comentarios: no se compila ni afecta a la app.
//  Reúne los cambios típicos que pueden pedirte en un ejercicio, con la ruta
//  exacta del archivo y el código listo para copiar.
//
//  ÍNDICE
//   1. Cambiar el nombre de la aplicación
//   2. Cambiar el icono de la aplicación
//   3. Cambiar los colores y el tema (claro / oscuro)
//   4. Cambiar la tipografía
//   5. Cambiar el logotipo
//   6. Cambiar textos, reglas de contraseña, DNI y tiempos
//   7. Ajustar el diseño adaptable (móvil / tableta / escritorio)
//   8. Agregar una sección al menú lateral / inferior
//   9. Crear un ejercicio y mostrarlo en el dashboard
//  10. Formulario con validaciones (ejemplo completo)
//  11. CRUD con Cloud Firestore (crear, listar, editar, eliminar)
//  12. Búsqueda, filtros y ordenamiento
//  13. Cálculos y reportes (totales, promedios, resúmenes)
//  14. Agregar un campo nuevo al registro (p. ej. teléfono)
//  15. Roles (usuario / administrador)
//  16. Cambiar de proyecto de Firebase
//  17. Ejecutar, compilar y desplegar
//  18. Errores frecuentes y cómo resolverlos
//
//  REGLA DE ORO: no modifiques la autenticación (lib/services/auth_service.dart,
//  lib/providers/auth_provider.dart, lib/screens/auth/, lib/core/routes/) salvo
//  que el ejercicio lo pida expresamente. Todo lo demás se puede cambiar.
//
//  Después de cada cambio ejecuta:
//      flutter analyze
//      flutter test
//
// =============================================================================
//  1. CAMBIAR EL NOMBRE DE LA APLICACIÓN
// =============================================================================
//
//  El nombre aparece en varios lugares. Cambia TODOS para que sea coherente.
//
//  a) Dentro de la app (login, menú lateral, títulos, «Acerca de»):
//     lib/core/constants/app_constants.dart
//
//       static const String appName = 'MiTienda';            // antes 'FlowApp'
//       static const String appTagline = 'Ventas bajo control.';
//       static const String appVersion = '2.0.0';
//
//  b) Nombre bajo el icono en Android:
//     android/app/src/main/AndroidManifest.xml
//
//       <application android:label="MiTienda" ...>
//
//  c) Pestaña del navegador y app instalable en web:
//     web/index.html      ->  <title>MiTienda</title>
//                             <meta name="apple-mobile-web-app-title" content="MiTienda">
//                             <meta name="description" content="...">
//     web/manifest.json   ->  "name": "MiTienda", "short_name": "MiTienda"
//
//  d) Título de la ventana y propiedades del .exe en Windows:
//     windows/runner/main.cpp   ->  window.Create(L"MiTienda", origin, size)
//     windows/runner/Runner.rc  ->  "FileDescription" y "ProductName"
//
//  e) (Opcional) Identificador del paquete Android, si te lo piden:
//     android/app/build.gradle.kts
//         namespace = "com.miempresa.mitienda"
//         applicationId = "com.miempresa.mitienda"
//     Mueve MainActivity.kt a android/app/src/main/kotlin/com/miempresa/mitienda/
//     y cambia su primera línea:  package com.miempresa.mitienda
//     IMPORTANTE: después ejecuta de nuevo FlutterFire para registrar el nuevo
//     paquete en Firebase (ver sección 16):
//         flutterfire configure --project=parcialflutter-b50cf --platforms=android,web,windows
//
//  f) Nombre del paquete Dart (el `name:` de pubspec.yaml): NO lo cambies salvo
//     que sea obligatorio; rompe todos los imports `package:proyectoflutter/...`.
//
// =============================================================================
//  2. CAMBIAR EL ICONO DE LA APLICACIÓN
// =============================================================================
//
//  Opción recomendada: paquete flutter_launcher_icons.
//
//  1) Copia tu imagen cuadrada PNG (1024x1024) en  assets/icono.png
//  2) En pubspec.yaml:
//
//       dev_dependencies:
//         flutter_launcher_icons: ^0.14.4
//
//       flutter_launcher_icons:
//         image_path: "assets/icono.png"
//         android: true
//         ios: false
//         web:
//           generate: true
//           background_color: "#F5F7FF"
//           theme_color: "#3478F6"
//         windows:
//           generate: true
//           icon_size: 256
//
//  3) Ejecuta:
//       flutter pub get
//       dart run flutter_launcher_icons
//
//  Opción manual: reemplaza los archivos con el mismo nombre y tamaño en
//    android/app/src/main/res/mipmap-*/ic_launcher.png
//    web/favicon.png y web/icons/*.png
//    windows/runner/resources/app_icon.ico
//
// =============================================================================
//  3. CAMBIAR LOS COLORES Y EL TEMA
// =============================================================================
//
//  a) Paleta de marca (un solo lugar): lib/core/theme/app_colors.dart
//
//       static const Color primary = Color(0xFF16A34A);   // verde en vez de azul
//       static const Color violet  = Color(0xFF0D9488);   // segundo color del degradado
//       static const Color navy    = Color(0xFF0F2E1D);   // barra lateral
//       static const Color background = Color(0xFFF4FBF6);
//
//     El formato es 0xFF + código hexadecimal (#16A34A -> 0xFF16A34A).
//     Los botones principales, el banner y el logo usan `brandGradient`.
//     Si quieren un color plano en lugar de degradado:
//
//       static const LinearGradient brandGradient = LinearGradient(
//         colors: [primary, primary],
//       );
//
//  b) Colores del tema oscuro: los `dark...` de app_colors.dart y
//     `AppPalette.dark` en lib/core/theme/app_theme.dart.
//
//  c) Bordes redondeados y sombras: clases AppRadius y AppShadows en
//     lib/core/theme/app_theme.dart  (sm = 12, md = 14, lg = 18).
//
//  d) Tema por defecto (hoy es claro). En lib/providers/theme_provider.dart,
//     método _read, cambia el valor de `orElse`:
//
//       orElse: () => ThemeMode.dark,     // oscuro por defecto
//       orElse: () => ThemeMode.system,   // según el sistema operativo
//
//     (Si el usuario ya eligió un tema en Configuración, se respeta su elección.)
//
//  e) Usar los colores dentro de tus pantallas (así cambian solos con el tema):
//
//       final theme = Theme.of(context);
//       theme.colorScheme.primary        // azul principal
//       theme.colorScheme.surface        // fondo de tarjetas
//       theme.colorScheme.onSurface      // texto principal
//       context.palette.textSecondary    // texto secundario
//       context.palette.success          // verde de éxito
//       context.palette.warning          // advertencia
//       AppColors.error                  // rojo de error
//
//     Evita escribir colores fijos como Colors.black en los textos: en el tema
//     oscuro no se verían.
//
// =============================================================================
//  4. CAMBIAR LA TIPOGRAFÍA
// =============================================================================
//
//  Opción A (sin internet, recomendada): fuente como asset.
//   1) Descarga los .ttf (por ejemplo Poppins) en  assets/fonts/
//   2) pubspec.yaml, dentro de `flutter:`:
//
//       fonts:
//         - family: Poppins
//           fonts:
//             - asset: assets/fonts/Poppins-Regular.ttf
//             - asset: assets/fonts/Poppins-SemiBold.ttf
//               weight: 600
//             - asset: assets/fonts/Poppins-Bold.ttf
//               weight: 700
//
//   3) lib/core/theme/app_theme.dart, en _build:
//
//       final base = ThemeData(
//         useMaterial3: true,
//         colorScheme: scheme,
//         brightness: brightness,
//         fontFamily: 'Poppins',          // <- agrega esta línea
//       );
//
//  Opción B: paquete google_fonts (descarga la fuente en tiempo de ejecución):
//       flutter pub add google_fonts
//       final base = ThemeData(..., textTheme: GoogleFonts.poppinsTextTheme());
//
// =============================================================================
//  5. CAMBIAR EL LOGOTIPO
// =============================================================================
//
//  lib/widgets/app_logo.dart dibuja el logo sin imágenes externas.
//   - Cambiar el símbolo: reemplaza Icons.waves_rounded por otro icono, p. ej.
//       Icons.storefront_rounded, Icons.school_rounded, Icons.local_hospital_rounded
//   - Usar una imagen propia: agrégala a assets (pubspec.yaml -> assets:) y en
//     lugar del Container con el icono usa:
//       Image.asset('assets/logo.png', width: size, height: size)
//
// =============================================================================
//  6. TEXTOS, CONTRASEÑA, DNI Y TIEMPOS
// =============================================================================
//
//  a) Reglas de contraseña: lib/core/validators/validators.dart
//
//       static const standard = PasswordPolicy(
//         minLength: 10,
//         requireUppercase: true,   // exige mayúscula
//         requireSymbol: true,      // exige símbolo
//       );
//
//     La lista de requisitos y el indicador de seguridad se actualizan solos.
//
//  b) Longitud del DNI / nombres y espera para reenviar el correo:
//     lib/core/constants/app_constants.dart
//       static const int dniLength = 8;
//       static const int maxNameLength = 50;
//       static const int resendCooldownSeconds = 60;
//     Si cambias el DNI, ajusta también validDni() en firestore.rules
//     ('^[0-9]{8}$' -> el nuevo largo) y despliega las reglas.
//
//  c) Mensajes de error de Firebase en español: lib/core/utils/app_exception.dart
//
//  d) Textos de las pantallas: están en cada archivo de lib/screens/.
//     Ejemplo: el saludo del dashboard está en _WelcomeBanner
//     (lib/screens/home/home_screen.dart): '¡Hola, $name!'.
//
// =============================================================================
//  7. DISEÑO ADAPTABLE
// =============================================================================
//
//  Puntos de quiebre: lib/core/constants/breakpoints.dart
//       tablet = 600     (menos de 600 px = móvil)
//       desktop = 1024   (desde 1024 px = escritorio, barra lateral completa)
//       formMaxWidth / dialogMaxWidth / contentMaxWidth = anchos máximos
//
//  Uso en una pantalla:
//
//       ResponsiveLayout(
//         mobile: (_) => const MiVistaUnaColumna(),
//         tablet: (_) => const MiVistaDosColumnas(),
//         desktop: (_) => const MiVistaTresColumnas(),
//       )
//
//       if (Breakpoints.isMobile(context)) { ... }
//
//  Para centrar y limitar el ancho de una página:
//       MaxWidthBox(maxWidth: 900, child: ...)
//
//  Cuadrícula que se adapta sola (1, 2 o 4 columnas):
//
//       LayoutBuilder(builder: (context, c) {
//         final columnas = c.maxWidth >= 900 ? 4 : c.maxWidth >= 520 ? 2 : 1;
//         final ancho = ((c.maxWidth - 16 * (columnas - 1)) / columnas).floorToDouble();
//         return Wrap(
//           spacing: 16,
//           runSpacing: 16,
//           children: [for (final item in items) SizedBox(width: ancho, child: MiTarjeta(item))],
//         );
//       })
//
// =============================================================================
//  8. AGREGAR UNA SECCIÓN AL MENÚ
// =============================================================================
//
//  lib/screens/home/home_screen.dart
//
//  1) Agrega un valor al enum HomeSection (el orden es el orden del menú):
//
//       enum HomeSection {
//         inicio('Inicio', Icons.space_dashboard_outlined, Icons.space_dashboard),
//         productos('Productos', Icons.inventory_2_outlined, Icons.inventory_2), // NUEVO
//         perfil(...),
//         ...
//       }
//
//  2) Devuelve su vista en _buildSection:
//
//       case HomeSection.productos:
//         return const ProductosPage();   // de lib/exercises/...
//
//  Aparece automáticamente en la barra lateral (escritorio/tableta) y en la
//  barra inferior (móvil). En móvil caben bien hasta 5 secciones.
//
// =============================================================================
//  9. CREAR UN EJERCICIO Y MOSTRARLO EN EL DASHBOARD
// =============================================================================
//
//  1) Crea la carpeta:  lib/exercises/mi_ejercicio/
//  2) Crea la página    lib/exercises/mi_ejercicio/mi_ejercicio_page.dart
//
//       import 'package:flutter/material.dart';
//
//       class MiEjercicioPage extends StatelessWidget {
//         const MiEjercicioPage({super.key});
//
//         @override
//         Widget build(BuildContext context) {
//           return Card(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Text('Mi ejercicio',
//                   style: Theme.of(context).textTheme.titleLarge),
//             ),
//           );
//         }
//       }
//
//  3) Muéstrala debajo de la tarjeta del usuario, en
//     lib/screens/home/exercise_module.dart:
//
//       @override
//       Widget build(BuildContext context) {
//         return const Padding(
//           padding: EdgeInsets.only(top: 24),
//           child: MiEjercicioPage(),
//         );
//       }
//
//  Datos del usuario que inició sesión (en cualquier pantalla privada):
//
//       final perfil = context.watch<AuthProvider>().profile!;
//       perfil.uid  perfil.nombre  perfil.apellido  perfil.nombreCompleto
//       perfil.dni  perfil.correo  perfil.fechaNacimiento
//
// =============================================================================
//  10. FORMULARIO CON VALIDACIONES
// =============================================================================
//
//  Reutiliza CustomTextField, PrimaryButton, StatusBanner y Validators.
//
//       class ProductoForm extends StatefulWidget {
//         const ProductoForm({super.key});
//         @override
//         State<ProductoForm> createState() => _ProductoFormState();
//       }
//
//       class _ProductoFormState extends State<ProductoForm> {
//         final _formKey = GlobalKey<FormState>();
//         final _nombre = TextEditingController();
//         final _precio = TextEditingController();
//         bool _guardando = false;
//         String? _error;
//
//         @override
//         void dispose() {
//           _nombre.dispose();
//           _precio.dispose();
//           super.dispose();
//         }
//
//         // Validador propio: número decimal mayor que cero.
//         String? _validarPrecio(String? v) {
//           final n = double.tryParse((v ?? '').replaceAll(',', '.'));
//           if (v == null || v.trim().isEmpty) return 'Ingresa el precio.';
//           if (n == null) return 'Ingresa un número válido.';
//           if (n <= 0) return 'El precio debe ser mayor que cero.';
//           return null;
//         }
//
//         Future<void> _guardar() async {
//           if (_guardando) return;                       // evita doble envío
//           if (!_formKey.currentState!.validate()) return;
//           setState(() { _guardando = true; _error = null; });
//           try {
//             // await ProductoService().crear(...);
//           } catch (e) {
//             setState(() => _error = AppException.from(e).message);
//           } finally {
//             if (mounted) setState(() => _guardando = false);
//           }
//         }
//
//         @override
//         Widget build(BuildContext context) {
//           return Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 if (_error != null)
//                   StatusBanner(message: _error!, type: StatusType.error),
//                 CustomTextField(
//                   label: 'Nombre',
//                   icon: Icons.label_outline,
//                   controller: _nombre,
//                   validator: (v) => (v == null || v.trim().isEmpty)
//                       ? 'Ingresa el nombre.' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 CustomTextField(
//                   label: 'Precio',
//                   icon: Icons.attach_money,
//                   controller: _precio,
//                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                   inputFormatters: [
//                     FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
//                   ],
//                   validator: _validarPrecio,
//                 ),
//                 const SizedBox(height: 24),
//                 PrimaryButton(label: 'Guardar', loading: _guardando, onPressed: _guardar),
//               ],
//             ),
//           );
//         }
//       }
//
//  Imports necesarios: package:flutter/services.dart (formatters) y los de
//  lib/widgets/ y lib/core/utils/app_exception.dart.
//
//  Abrir el formulario como modal (bottom sheet en móvil, diálogo en web/PC):
//
//       showAppModal<void>(
//         context: context,
//         builder: (_) => const AppModalFrame(
//           icon: Icons.add_box_outlined,
//           title: 'Nuevo producto',
//           subtitle: 'Completa los datos.',
//           child: ProductoForm(),
//         ),
//       );
//
//  Confirmación antes de una acción peligrosa:
//
//       final ok = await showConfirmDialog(
//         context: context,
//         title: 'Eliminar producto',
//         message: '¿Seguro que deseas eliminarlo?',
//         confirmLabel: 'Eliminar',
//         destructive: true,
//       );
//       if (ok) { ... }
//
// =============================================================================
//  11. CRUD CON CLOUD FIRESTORE
// =============================================================================
//
//  Datos privados de cada usuario en:  users/{uid}/productos/{id}
//
//  a) MODELO  lib/exercises/productos/producto.dart
//
//       import 'package:cloud_firestore/cloud_firestore.dart';
//
//       class Producto {
//         const Producto({required this.id, required this.nombre,
//             required this.precio, required this.stock, this.creadoEn});
//
//         final String id;
//         final String nombre;
//         final double precio;
//         final int stock;
//         final DateTime? creadoEn;
//
//         double get subtotal => precio * stock;
//
//         factory Producto.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
//           final d = doc.data()!;
//           return Producto(
//             id: doc.id,
//             nombre: d['nombre'] as String,
//             precio: (d['precio'] as num).toDouble(),
//             stock: (d['stock'] as num).toInt(),
//             creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
//           );
//         }
//       }
//
//  b) SERVICIO  lib/exercises/productos/producto_service.dart
//
//       class ProductoService {
//         ProductoService({FirebaseFirestore? db})
//             : _db = db ?? FirebaseFirestore.instance;
//         final FirebaseFirestore _db;
//
//         CollectionReference<Map<String, dynamic>> _col(String uid) =>
//             _db.collection('users').doc(uid).collection('productos');
//
//         // LISTAR en tiempo real (se actualiza solo)
//         Stream<List<Producto>> observar(String uid) => _col(uid)
//             .orderBy('creadoEn', descending: true)
//             .snapshots()
//             .map((s) => s.docs.map(Producto.fromDoc).toList());
//
//         // CREAR
//         Future<void> crear(String uid, String nombre, double precio, int stock) =>
//             _col(uid).add({
//               'nombre': nombre,
//               'precio': precio,
//               'stock': stock,
//               'creadoEn': FieldValue.serverTimestamp(),
//             });
//
//         // EDITAR
//         Future<void> editar(String uid, Producto p) =>
//             _col(uid).doc(p.id).update({
//               'nombre': p.nombre,
//               'precio': p.precio,
//               'stock': p.stock,
//             });
//
//         // ELIMINAR
//         Future<void> eliminar(String uid, String id) => _col(uid).doc(id).delete();
//       }
//
//  c) PÁGINA  lib/exercises/productos/productos_page.dart
//
//       class ProductosPage extends StatelessWidget {
//         const ProductosPage({super.key});
//
//         @override
//         Widget build(BuildContext context) {
//           final uid = context.watch<AuthProvider>().profile!.uid;
//           final service = ProductoService();
//           return StreamBuilder<List<Producto>>(
//             stream: service.observar(uid),
//             builder: (context, snap) {
//               if (snap.hasError) {
//                 return StatusBanner(
//                   message: AppException.from(snap.error!).message,
//                   type: StatusType.error);
//               }
//               if (!snap.hasData) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               final productos = snap.data!;
//               if (productos.isEmpty) {
//                 return const Center(child: Text('Aún no hay productos.'));
//               }
//               return ListView.separated(
//                 shrinkWrap: true,                       // dentro de un scroll
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: productos.length,
//                 separatorBuilder: (_, _) => const Divider(height: 1),
//                 itemBuilder: (context, i) {
//                   final p = productos[i];
//                   return ListTile(
//                     title: Text(p.nombre),
//                     subtitle: Text('S/ ${p.precio.toStringAsFixed(2)} · Stock: ${p.stock}'),
//                     trailing: IconButton(
//                       tooltip: 'Eliminar',
//                       icon: const Icon(Icons.delete_outline),
//                       onPressed: () => service.eliminar(uid, p.id),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         }
//       }
//
//  En pantallas anchas puedes usar una tabla en lugar de ListView:
//       DataTable(columns: [...], rows: [for (final p in productos) DataRow(cells: [...])])
//     envuelta en SingleChildScrollView(scrollDirection: Axis.horizontal) para
//     que no se desborde en móvil.
//
//  d) REGLAS  firestore.rules  (pégalas dentro de `match /databases/{database}/documents { ... }`,
//     ANTES del bloque final `match /{document=**}`):
//
//       match /users/{uid}/productos/{productoId} {
//         allow read, delete: if isOwner(uid);
//         allow create: if isOwner(uid)
//           && request.resource.data.keys().hasOnly(['nombre', 'precio', 'stock', 'creadoEn'])
//           && request.resource.data.nombre is string
//           && request.resource.data.nombre.size() > 0
//           && request.resource.data.nombre.size() <= 80
//           && request.resource.data.precio is number
//           && request.resource.data.precio > 0
//           && request.resource.data.stock is int
//           && request.resource.data.stock >= 0
//           && request.resource.data.creadoEn == request.time;
//         allow update: if isOwner(uid)
//           && request.resource.data.diff(resource.data).affectedKeys()
//                .hasOnly(['nombre', 'precio', 'stock'])
//           && request.resource.data.precio is number
//           && request.resource.data.precio > 0
//           && request.resource.data.stock is int
//           && request.resource.data.stock >= 0;
//       }
//
//     Y despliégalas:   firebase deploy --only firestore:rules
//
//     Datos COMPARTIDOS entre todos los usuarios (p. ej. un catálogo público):
//     colección de primer nivel `productos/{id}` con
//       allow read: if signedIn();
//       allow write: if isAdmin();   // ver sección 15
//
//  e) Consultas útiles:
//       .where('stock', isLessThan: 5)                 // stock bajo
//       .where('categoria', isEqualTo: 'Bebidas')
//       .orderBy('precio').limit(20)
//     Si combinas where + orderBy sobre campos distintos, Firestore pedirá un
//     índice: el error trae un enlace para crearlo en la consola.
//
// =============================================================================
//  12. BÚSQUEDA, FILTROS Y ORDENAMIENTO
// =============================================================================
//
//  Para listas pequeñas/medianas, filtra en el cliente (Firestore no tiene
//  búsqueda por texto parcial):
//
//       String _busqueda = '';
//       String _orden = 'nombre';
//
//       TextField(
//         decoration: const InputDecoration(
//           hintText: 'Buscar…', prefixIcon: Icon(Icons.search)),
//         onChanged: (v) => setState(() => _busqueda = v.trim().toLowerCase()),
//       ),
//
//       final visibles = productos
//           .where((p) => p.nombre.toLowerCase().contains(_busqueda))
//           .toList()
//         ..sort((a, b) => _orden == 'precio'
//             ? a.precio.compareTo(b.precio)
//             : a.nombre.compareTo(b.nombre));
//
//  Filtro por categoría con chips:
//       Wrap(spacing: 8, children: [
//         for (final c in ['Todas', 'Bebidas', 'Snacks'])
//           ChoiceChip(label: Text(c), selected: _cat == c,
//               onSelected: (_) => setState(() => _cat = c)),
//       ])
//
//  Recuerda: el campo de búsqueda solo debe mostrarse si realmente filtra algo.
//
// =============================================================================
//  13. CÁLCULOS Y REPORTES
// =============================================================================
//
//  Pon la lógica de cálculo en funciones puras (fáciles de probar):
//  lib/exercises/productos/calculos.dart
//
//       class Calculos {
//         static double total(List<Producto> ps) =>
//             ps.fold(0, (s, p) => s + p.subtotal);
//
//         static double promedio(List<double> valores) =>
//             valores.isEmpty ? 0 : valores.reduce((a, b) => a + b) / valores.length;
//
//         static double conIgv(double monto, {double tasa = 0.18}) =>
//             double.parse((monto * (1 + tasa)).toStringAsFixed(2));
//
//         static double descuento(double monto, double porcentaje) =>
//             monto - monto * porcentaje / 100;
//
//         static String condicion(double nota) =>       // notas vigesimales
//             nota >= 10.5 ? 'Aprobado' : 'Desaprobado';
//       }
//
//  Prueba unitaria  test/calculos_test.dart:
//       test('IGV', () => expect(Calculos.conIgv(100), 118.0));
//
//  Tarjetas de resumen (reporte) con el mismo estilo del dashboard:
//
//       Card(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Text('Total en inventario', style: Theme.of(context).textTheme.bodySmall),
//             const SizedBox(height: 6),
//             Text('S/ ${Calculos.total(productos).toStringAsFixed(2)}',
//                 style: Theme.of(context).textTheme.headlineSmall),
//           ]),
//         ),
//       )
//
//  Formatear fechas y moneda (paquete intl, ya instalado):
//       DateFormat('dd/MM/yyyy').format(fecha)
//       NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ').format(monto)
//
// =============================================================================
//  14. AGREGAR UN CAMPO NUEVO AL REGISTRO (ejemplo: teléfono)
// =============================================================================
//
//  Toca 5 lugares, en este orden:
//
//  1) Validador  lib/core/validators/validators.dart
//       static String? telefono(String? v) {
//         final t = (v ?? '').trim();
//         if (t.isEmpty) return 'Ingresa tu teléfono.';
//         if (!RegExp(r'^9\d{8}$').hasMatch(t)) return 'Ingresa un celular de 9 dígitos.';
//         return null;
//       }
//
//  2) Modelo  lib/models/user_profile.dart
//       - Agrega `final String telefono;` a RegistrationData y a UserProfile.
//       - En UserProfile.fromMap:  telefono: map['telefono'] as String? ?? '',
//
//  3) Formulario  lib/screens/auth/register_modal.dart
//       - Controller: final _telefonoCtrl = TextEditingController(); (y dispose)
//       - Campo (copia el del DNI y cambia):
//           CustomTextField(
//             label: 'Teléfono',
//             icon: Icons.phone_outlined,
//             controller: _telefonoCtrl,
//             keyboardType: TextInputType.phone,
//             inputFormatters: [FilteringTextInputFormatter.digitsOnly,
//                               LengthLimitingTextInputFormatter(9)],
//             validator: Validators.telefono,
//           ),
//       - En _submit, dentro de RegistrationData(...):
//           telefono: _telefonoCtrl.text.trim(),
//
//  4) Servicio  lib/services/user_service.dart, en createPendingProfile:
//           'telefono': data.telefono,
//
//  5) Reglas  firestore.rules:
//       - Agrega 'telefono' a la lista de profileKeys().
//       - En `allow create` de users:
//           && request.resource.data.telefono.matches('^9[0-9]{8}$')
//       - Si debe poder editarse en «Mis datos», agrégalo también a la lista
//         de hasOnly([...]) del `allow update`.
//       - Despliega:  firebase deploy --only firestore:rules
//
//  IMPORTANTE: los usuarios ya registrados no tienen el campo. Por eso fromMap
//  usa `?? ''`. Si las reglas lo exigen, esos usuarios solo podrán actualizar
//  su perfil después de completarlo.
//
//  Mostrarlo: en lib/screens/profile/profile_screen.dart agrega otro _InfoTile.
//
// =============================================================================
//  15. ROLES (USUARIO / ADMINISTRADOR)
// =============================================================================
//
//  El cliente NUNCA debe poder asignarse el rol de administrador.
//
//  1) Reglas  firestore.rules
//       - Agrega 'rol' a profileKeys() y en `allow create` de users:
//           && request.resource.data.rol == 'usuario'
//       - NO incluyas 'rol' en el hasOnly del `allow update` (así nadie lo cambia
//         desde la app).
//       - Función de ayuda (junto a las demás funciones):
//           function isAdmin() {
//             return signedIn()
//               && get(userPath(request.auth.uid)).data.get('rol', 'usuario') == 'admin';
//           }
//       - Ejemplo: el admin puede leer todos los perfiles:
//           allow get, list: if isOwner(uid) || isAdmin();
//
//  2) Al registrar (user_service.dart, createPendingProfile):  'rol': 'usuario',
//
//  3) Modelo: `final String rol;` y en fromMap: rol: map['rol'] as String? ?? 'usuario',
//       bool get esAdmin => rol == 'admin';
//
//  4) Nombrar un administrador: Firebase Console -> Firestore -> users/{uid} ->
//     cambia el campo rol a "admin" (la consola no pasa por las reglas).
//
//  5) Mostrar opciones solo al admin (home_screen.dart):
//       final secciones = HomeSection.values
//           .where((s) => s != HomeSection.admin || profile.esAdmin);
//     Ocultar un botón NO es seguridad: la protección real son las reglas.
//
// =============================================================================
//  16. CAMBIAR DE PROYECTO DE FIREBASE
// =============================================================================
//
//       firebase login                      # cuenta dueña del proyecto
//       firebase projects:list
//       flutterfire configure --project=NUEVO-ID --platforms=android,web,windows
//
//  Esto regenera lib/firebase_options.dart y android/app/google-services.json.
//  Luego:
//   1) En .firebaserc cambia "default" por NUEVO-ID.
//   2) firebase deploy --only auth,firestore:rules
//        (habilita correo/contraseña y publica las reglas; si Firestore no existe
//         se crea. Para elegir la región antes:
//         firebase firestore:databases:create "(default)" --location=southamerica-west1)
//   3) Publica una vez Firebase Hosting (aunque no lo uses). Sin eso, la página
//      que abre el enlace de verificación del correo puede fallar:
//         firebase deploy --only hosting
//      (necesitas una sección "hosting" en firebase.json con una carpeta public).
//
//  Nunca copies firebase_options.dart a mano ni inventes claves.
//
// =============================================================================
//  17. EJECUTAR, COMPILAR Y DESPLEGAR
// =============================================================================
//
//       flutter pub get
//       flutter run -d chrome              # web
//       flutter run -d windows             # Windows
//       flutter devices                    # ver el id del Android conectado
//       flutter run -d <id>                # Android
//
//       flutter build web                  # resultado en build/web
//       flutter build windows              # build/windows/x64/runner/Release
//       flutter build apk                  # build/app/outputs/flutter-apk
//
//  Publicar la versión web en Firebase Hosting:
//    firebase.json ->  "hosting": { "public": "build/web",
//                        "rewrites": [ { "source": "**", "destination": "/index.html" } ] }
//    flutter build web && firebase deploy --only hosting
//
// =============================================================================
//  18. ERRORES FRECUENTES
// =============================================================================
//
//  - «permission-denied» al guardar: falta la regla en firestore.rules, el
//    documento tiene campos no permitidos (hasOnly) o no desplegaste las reglas.
//  - «The query requires an index»: abre el enlace del error y crea el índice.
//  - «RenderFlex overflowed»: usa Expanded/Flexible dentro de Row/Column,
//    SingleChildScrollView en pantallas largas y Wrap en lugar de Row para
//    elementos que deban bajar de línea.
//  - El enlace del correo muestra un error: usa «¿El enlace muestra un error?
//    Pégalo aquí» en la pantalla de verificación, o reenvía el correo.
//  - Android no conecta en release: android.permission.INTERNET debe estar en
//    android/app/src/main/AndroidManifest.xml (ya está).
//  - Cambiaste pubspec.yaml: ejecuta flutter pub get y reinicia la app (no basta
//    con hot reload).
//  - Tras cambiar colores/tema: usa hot restart (R) para ver todo actualizado.
