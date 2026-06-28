// Test básico de humo. La app real (JukaApp) requiere inicializar Firebase,
// así que no se instancia acá. Este test solo verifica que el entorno de
// testing funcione. Los tests de features se agregan por separado.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('entorno de test operativo', () {
    expect(1 + 1, 2);
  });
}
