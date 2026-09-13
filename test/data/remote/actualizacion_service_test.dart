import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/remote/actualizacion_service.dart';

/// Solo la logica de comparacion: [ActualizacionService.evaluar] no toca
/// red, asi que no hace falta un cliente de Supabase para probarla.
void main() {
  group('evaluar', () {
    test('sin fila en app_config, no hay nada que avisar', () {
      expect(ActualizacionService.evaluar(null, 'abc123'), isNull);
    });

    test('mismo sha que el instalado: sin aviso', () {
      final fila = {'build_sha': 'abc123', 'apk_url': 'https://x/app.apk'};
      expect(ActualizacionService.evaluar(fila, 'abc123'), isNull);
    });

    test('sha distinto: avisa con la URL del APK', () {
      final fila = {'build_sha': 'nuevo456', 'apk_url': 'https://x/app.apk'};
      final resultado = ActualizacionService.evaluar(fila, 'abc123');

      expect(resultado, isNotNull);
      expect(resultado!.apkUrl, 'https://x/app.apk');
    });

    test('fila sin build_sha o sin apk_url: no revienta, no avisa', () {
      expect(
        ActualizacionService.evaluar({'apk_url': 'https://x/app.apk'}, 'abc'),
        isNull,
      );
      expect(
        ActualizacionService.evaluar({'build_sha': 'nuevo'}, 'abc'),
        isNull,
      );
    });
  });
}
