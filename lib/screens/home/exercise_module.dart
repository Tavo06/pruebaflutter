import 'package:flutter/material.dart';

/// Módulo del ejercicio: contenido REEMPLAZABLE de la sección «Inicio».
///
/// Por ahora está vacío: el dashboard solo muestra la tarjeta de bienvenida
/// del usuario. Cuando te asignen un ejercicio, devuelve aquí su vista
/// (formularios, listas, cálculos, reportes, CRUD…). Coloca el código propio
/// del ejercicio en `lib/exercises/<nombre_del_ejercicio>/`.
///
/// Ver ejemplos completos en `lib/guia/practica.dart`.
class ExerciseModule extends StatelessWidget {
  const ExerciseModule({super.key});

  @override
  Widget build(BuildContext context) {
    // Ejemplo: return const CalculadoraNotasPage();
    return const SizedBox.shrink();
  }
}
