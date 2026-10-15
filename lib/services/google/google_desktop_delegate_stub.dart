import 'google_sign_in_delegate.dart';

/// En compilaciones sin `dart:io` (web) no existe el flujo de escritorio.
GoogleSignInDelegate createDesktopGoogleSignInDelegate() =>
    const UnsupportedGoogleSignInDelegate();
