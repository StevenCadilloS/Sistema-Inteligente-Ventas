import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EmocionDetectada {
  const EmocionDetectada({
    required this.emotion,
    required this.confidence,
    this.smileProbability,
    this.status = 'ok',
  });

  factory EmocionDetectada.fromMap(Map<dynamic, dynamic> mapa) {
    return EmocionDetectada(
      emotion: mapa['emotion'] as String,
      confidence: (mapa['confidence'] as num).toDouble(),
      smileProbability: (mapa['smileProbability'] as num?)?.toDouble(),
      status: mapa['status'] as String? ?? 'ok',
    );
  }

  final String emotion;
  final double confidence;
  final double? smileProbability;
  final String status;
}

/// Puente con el detector de respuesta facial nativo (Kotlin + ML Kit).
/// Las imagenes de la camara no salen del dispositivo: lo que cruza
/// este canal es el nombre de la emocion y su confianza.
class EmotionChannel {
  const EmotionChannel();

  static const _channel = EventChannel('com.tuapp.tienda_adaptativa/emotion');

  /// Si hay detector en esta plataforma. Solo Android: el modulo es nativo, y
  /// en web o escritorio el canal no tiene implementacion al otro lado.
  bool get disponible =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Emociones detectadas, o un stream vacio donde no hay detector.
  ///
  /// Vacio y no una excepcion: la tienda funciona igual sin camara —se compra
  /// a precio normal, que es lo que manda el README cuando no hay senal— y
  /// reventar al suscribirse dejaba la pantalla con un error rojo en cada
  /// seleccion de producto al probar en Chrome.
  Stream<EmocionDetectada> get emociones {
    if (!disponible) return const Stream<EmocionDetectada>.empty();

    return _mapear(_channel.receiveBroadcastStream());
  }

  /// Lecturas sin estabilizar para calibrar el detector fotograma a fotograma.
  Stream<EmocionDetectada> get diagnostico {
    if (!disponible) return const Stream<EmocionDetectada>.empty();
    return _mapear(
      _channel.receiveBroadcastStream(const {'diagnostic': true}),
    );
  }

  Stream<EmocionDetectada> _mapear(Stream<dynamic> eventos) =>
      eventos.map((evento) => EmocionDetectada.fromMap(evento as Map));
}
