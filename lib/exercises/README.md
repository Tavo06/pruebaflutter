# Ejercicios

Coloca aquí el código propio de cada ejercicio, una carpeta por ejercicio:

```
lib/exercises/
└── calculadora_notas/
    ├── models/            # Modelos propios del ejercicio
    ├── services/          # Acceso a Firestore u otras fuentes del ejercicio
    ├── widgets/           # Componentes visuales del ejercicio
    └── calculadora_notas_page.dart   # Vista principal del ejercicio
```

Luego muéstralo desde `lib/screens/home/exercise_module.dart`, que es el único
punto de conexión con el dashboard:

```dart
class ExerciseModule extends StatelessWidget {
  const ExerciseModule({super.key});

  @override
  Widget build(BuildContext context) => const CalculadoraNotasPage();
}
```

Reutiliza los componentes de `lib/widgets/` (`CustomTextField`, `PrimaryButton`,
`showAppModal`, `ResponsiveLayout`…) y los validadores de
`lib/core/validators/validators.dart` para mantener el mismo diseño.

Si el ejercicio guarda datos en Firestore, crea su colección (por ejemplo
`users/{uid}/notas/{id}` para datos privados del usuario) y añade sus reglas
en `firestore.rules` antes de desplegarlas.
