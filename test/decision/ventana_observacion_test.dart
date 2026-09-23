import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/decision/ventana_observacion.dart';

/// El reto del docente convertido en invariantes: si el cliente deja de mirar,
/// la ventana se congela, las emociones dejan de contarse y al volver se sigue
/// desde donde quedo, no desde cero.
void main() {
  // Reloj de mentira: aqui no hay fake_async ni WidgetTester, el tiempo lo
  // mueve la prueba a mano.
  late DateTime t;
  VentanaObservacion nueva({Duration total = const Duration(seconds: 8)}) =>
      VentanaObservacion(total: total, ahora: () => t);

  void avanzar(Duration d) => t = t.add(d);

  setUp(() => t = DateTime(2026, 1, 1, 12));

  group('contabilidad del tiempo', () {
    test('arranca en cero y corre', () {
      final v = nueva();
      expect(v.transcurrido, Duration.zero);
      expect(v.pausada, isFalse);

      avanzar(const Duration(seconds: 3));
      expect(v.transcurrido, const Duration(seconds: 3));
      expect(v.restante, const Duration(seconds: 5));
    });

    test('pausar congela lo transcurrido por mucho que pase el tiempo', () {
      final v = nueva();
      avanzar(const Duration(seconds: 4));
      v.pausar();

      avanzar(const Duration(minutes: 10));

      expect(v.transcurrido, const Duration(seconds: 4),
          reason: 'diez minutos de ausencia no consumen la ventana');
      expect(v.restante, const Duration(seconds: 4));
    });

    test('reanudar sigue desde donde quedo, no desde cero', () {
      final v = nueva();
      avanzar(const Duration(seconds: 4));
      v.pausar();
      avanzar(const Duration(seconds: 30));
      v.reanudar();

      expect(v.restante, const Duration(seconds: 4),
          reason: 'quedaban 4 s antes de la pausa y siguen quedando 4');

      avanzar(const Duration(seconds: 3));
      expect(v.restante, const Duration(seconds: 1));
    });

    test('el restante no baja de cero', () {
      final v = nueva();
      avanzar(const Duration(seconds: 20));
      expect(v.restante, Duration.zero);
    });

    test('pausar dos veces no cuenta el tiempo dos veces', () {
      final v = nueva();
      avanzar(const Duration(seconds: 2));
      v.pausar();
      v.pausar();
      avanzar(const Duration(seconds: 5));

      expect(v.transcurrido, const Duration(seconds: 2));
    });

    test('reanudar sin haber pausado no mueve nada', () {
      final v = nueva();
      avanzar(const Duration(seconds: 2));
      v.reanudar();

      expect(v.transcurrido, const Duration(seconds: 2));
      expect(v.pausada, isFalse);
    });
  });

  group('lecturas', () {
    test('en marcha se contabilizan', () {
      final v = nueva();
      expect(v.registrar('neutral'), isTrue);
      expect(v.registrar('triste'), isTrue);
      expect(v.lecturas, ['neutral', 'triste']);
    });

    test('en pausa se descartan', () {
      final v = nueva();
      v.registrar('neutral');
      v.pausar();

      expect(v.registrar('triste'), isFalse,
          reason: 'mientras este pausada no se contabilizan emociones');
      expect(v.lecturas, ['neutral']);
    });

    test('al reanudar se vuelven a contabilizar', () {
      final v = nueva();
      v.pausar();
      v.registrar('triste');
      v.reanudar();

      expect(v.registrar('enojo'), isTrue);
      expect(v.lecturas, ['enojo']);
    });

    test('la lista que se expone no se puede mutar desde fuera', () {
      final v = nueva();
      v.registrar('neutral');
      expect(() => v.lecturas.add('feliz'), throwsUnsupportedError);
    });
  });

  group('progreso para la barra', () {
    test('avanza con el tiempo y se congela en pausa', () {
      final v = nueva();
      avanzar(const Duration(seconds: 2));
      expect(v.progreso, closeTo(0.25, 0.001));

      v.pausar();
      avanzar(const Duration(seconds: 6));

      expect(v.progreso, closeTo(0.25, 0.001),
          reason: 'la barra se queda quieta: es la prueba visible de la pausa');
    });

    test('esta acotado a 1 aunque la ventana se pase', () {
      final v = nueva();
      avanzar(const Duration(seconds: 40));
      expect(v.progreso, 1);
    });

    test('una ventana de duracion cero no divide entre cero', () {
      final v = nueva(total: Duration.zero);
      expect(v.progreso, 1);
    });
  });
}
