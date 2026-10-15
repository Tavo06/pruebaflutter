import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/app_exception.dart';
import 'google_sign_in_delegate.dart';

GoogleSignInDelegate createDesktopGoogleSignInDelegate() =>
    DesktopGoogleSignInDelegate();

/// Windows: el SDK de Firebase para escritorio no implementa
/// `signInWithProvider` ni `signInWithPopup`, y `google_sign_in` no tiene
/// versión para Windows. Por eso se usa el flujo OAuth 2.0 para aplicaciones
/// instaladas que recomienda Google:
///
/// 1. Se abre el navegador del sistema con el selector de cuenta de Google.
/// 2. Google redirige a un servidor local temporal (`http://127.0.0.1:<puerto>`).
/// 3. El código se canjea por un ID token (con PKCE S256 y `state`).
/// 4. El ID token se entrega a Firebase con `signInWithCredential`.
///
/// Requiere un cliente OAuth de tipo «Aplicación de escritorio» del mismo
/// proyecto de Google Cloud, pasado al compilar:
///
/// ```
/// flutter run -d windows \
///   --dart-define=GOOGLE_DESKTOP_CLIENT_ID=xxxx.apps.googleusercontent.com \
///   --dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=xxxx
/// ```
///
/// Google considera el «secreto» de un cliente de escritorio no confidencial
/// (se distribuye con la app); la seguridad la aportan PKCE y la redirección
/// a loopback. Aun así no se escribe en el código ni en el repositorio.
class DesktopGoogleSignInDelegate extends GoogleSignInDelegate {
  DesktopGoogleSignInDelegate();

  static const _clientId = String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_ID');
  static const _clientSecret = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_SECRET',
  );
  static const _timeout = Duration(minutes: 5);

  HttpServer? _server;

  @override
  bool get runsOutsideApp => true;

  @override
  Future<UserCredential?> signIn(FirebaseAuth auth) async {
    if (_clientId.isEmpty) {
      throw const AppException(
        'El acceso con Google en Windows necesita un cliente OAuth de '
        'escritorio. Consulta el README, sección «Google Sign-In › Windows».',
      );
    }
    await _closeServer();

    final verifier = _randomString(64);
    final challenge = base64UrlEncode(
      sha256.convert(ascii.encode(verifier)).bytes,
    ).replaceAll('=', '');
    final state = _randomString(32);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    final redirectUri = 'http://127.0.0.1:${server.port}';

    try {
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': _clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'state': state,
        'prompt': 'select_account',
      });
      await _openBrowser(authUrl);

      final params = await _waitForRedirect(server).timeout(
        _timeout,
        onTimeout: () => null,
      );
      if (params == null) return null; // Cancelado o tiempo agotado.
      if (params['state'] != state) {
        throw const AppException(
          'La respuesta de Google no es válida. Inténtalo de nuevo.',
        );
      }
      final error = params['error'];
      if (error == 'access_denied') return null;
      final code = params['code'];
      if (error != null || code == null) {
        throw const AppException(
          'Google rechazó la solicitud. Revisa la configuración del cliente '
          'OAuth de escritorio.',
        );
      }

      final tokens = await _exchangeCode(code, verifier, redirectUri);
      return await auth.signInWithCredential(
        GoogleAuthProvider.credential(
          idToken: tokens.idToken,
          accessToken: tokens.accessToken,
        ),
      );
    } on SocketException {
      throw const AppException(
        'No hay conexión con el servidor. Revisa tu conexión a internet.',
      );
    } finally {
      await _closeServer();
    }
  }

  @override
  void cancel() {
    _closeServer();
  }

  Future<Map<String, String>?> _waitForRedirect(HttpServer server) {
    final completer = Completer<Map<String, String>?>();
    server.listen(
      (request) async {
        if (request.uri.path != '/') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        final query = request.uri.queryParameters;
        final ok = query.containsKey('code');
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(_resultPage(ok));
        await request.response.close();
        if (!completer.isCompleted) completer.complete(query);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(null);
      },
      onError: (Object _) {
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    return completer.future;
  }

  Future<({String idToken, String? accessToken})> _exchangeCode(
    String code,
    String verifier,
    String redirectUri,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(
        Uri.https('oauth2.googleapis.com', '/token'),
      );
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      );
      request.write(
        Uri(
          queryParameters: {
            'code': code,
            'client_id': _clientId,
            if (_clientSecret.isNotEmpty) 'client_secret': _clientSecret,
            'redirect_uri': redirectUri,
            'grant_type': 'authorization_code',
            'code_verifier': verifier,
          },
        ).query,
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final idToken = json['id_token'] as String?;
      if (response.statusCode != HttpStatus.ok || idToken == null) {
        if (json['error'] == 'invalid_client') {
          throw const AppException(
            'El cliente OAuth de escritorio no es válido. Revisa '
            'GOOGLE_DESKTOP_CLIENT_ID y GOOGLE_DESKTOP_CLIENT_SECRET.',
          );
        }
        throw const AppException(
          'Google no devolvió credenciales válidas. Inténtalo de nuevo.',
        );
      }
      return (idToken: idToken, accessToken: json['access_token'] as String?);
    } on FormatException {
      throw const AppException(
        'Google devolvió una respuesta inesperada. Inténtalo de nuevo.',
      );
    } finally {
      client.close();
    }
  }

  Future<void> _openBrowser(Uri url) async {
    try {
      // Abre la URL con el navegador predeterminado sin pasar por cmd.exe
      // (evita que los «&» de la URL se interpreten como comandos).
      await Process.run('rundll32', ['url.dll,FileProtocolHandler', '$url']);
    } catch (_) {
      throw const AppException(
        'No se pudo abrir el navegador para iniciar sesión con Google.',
      );
    }
  }

  Future<void> _closeServer() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  static String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  static String _resultPage(bool ok) => '''
<!doctype html><html lang="es"><head><meta charset="utf-8">
<title>Inicio de sesión con Google</title></head>
<body style="font-family:system-ui,sans-serif;text-align:center;padding:64px 16px">
<h2>${ok ? 'Listo' : 'Inicio de sesión cancelado'}</h2>
<p>Puedes cerrar esta ventana y volver a la aplicación.</p>
</body></html>''';
}
