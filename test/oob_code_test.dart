import 'package:flutter_test/flutter_test.dart';
import 'package:proyectoflutter/services/auth_service.dart';

void main() {
  const code = 'AbC-123_xyzAbC-123_xyz';
  test('extrae oobCode de enlaces de Firebase y envueltos', () {
    const base = 'https://p.firebaseapp.com/__/auth/action';
    expect(
      AuthService.extractOobCode(
        '$base?mode=verifyEmail&oobCode=$code&apiKey=k',
      ),
      code,
    );
    expect(
      AuthService.extractOobCode(
        '$base?mode=verifyEmail&amp;oobCode=$code&amp;lang=es',
      ),
      code,
    );
    expect(AuthService.extractOobCode('$base?oobCode=$code'), code);
    final wrapped =
        'https://safelinks.example/?url=${Uri.encodeComponent('$base?mode=verifyEmail&oobCode=$code')}';
    expect(AuthService.extractOobCode(wrapped), code);
    expect(AuthService.extractOobCode('  $code  '), code);
  });

  test('rechaza textos sin código', () {
    expect(AuthService.extractOobCode('https://ejemplo.com'), isNull);
    expect(AuthService.extractOobCode(''), isNull);
  });
}
