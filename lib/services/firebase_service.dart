import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Inicialización de Firebase para la plataforma actual.
///
/// `firebase_options.dart` lo genera FlutterFire CLI (`flutterfire configure`).
class FirebaseService {
  FirebaseService._();

  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
