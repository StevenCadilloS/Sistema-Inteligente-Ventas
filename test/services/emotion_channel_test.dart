import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/services/emotion_channel.dart';

void main() {
  test('convierte una lectura diagnostica completa', () {
    final lectura = EmocionDetectada.fromMap({
      'emotion': 'favorable',
      'confidence': 0.82,
      'smileProbability': 0.82,
      'status': 'ok',
    });

    expect(lectura.emotion, 'favorable');
    expect(lectura.confidence, 0.82);
    expect(lectura.smileProbability, 0.82);
    expect(lectura.status, 'ok');
  });

  test('conserva compatibilidad con eventos anteriores', () {
    final lectura = EmocionDetectada.fromMap({
      'emotion': 'desfavorable',
      'confidence': 0.75,
    });

    expect(lectura.smileProbability, isNull);
    expect(lectura.status, 'ok');
  });
}
