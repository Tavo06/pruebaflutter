import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/app_exception.dart';
import 'google_sign_in_delegate.dart';

/// Web: ventana emergente oficial de Firebase Authentication.
///
/// Requiere que el dominio esté en «Authorized domains» de Firebase
/// (`localhost` y `<proyecto>.firebaseapp.com` vienen autorizados).
class WebGoogleSignInDelegate extends GoogleSignInDelegate {
  const WebGoogleSignInDelegate();

  @override
  Future<UserCredential?> signIn(FirebaseAuth auth) async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters({'prompt': 'select_account'});
    try {
      return await auth.signInWithPopup(provider);
    } catch (e) {
      final error = AppException.google(e);
      if (error.isCancellation) return null;
      throw error;
    }
  }
}
