import 'package:flutter/material.dart';

import '../../exercises/finanzas/finanzas_page.dart';

/// Módulo del ejercicio: contenido REEMPLAZABLE de la sección «Inicio».
///
/// Muestra el ejercicio de finanzas personales (ingresos y gastos), cuyo
/// código está en `lib/exercises/finanzas/`.
///
/// Ver ejemplos completos en `lib/guia/practica.dart`.
class ExerciseModule extends StatelessWidget {
  const ExerciseModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const FinanzasPage();
  }
}
