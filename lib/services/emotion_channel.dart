import 'package:flutter/services.dart';

class EmocionDetectada {
  const EmocionDetectada({required this.emotion, required this.confidence});

  final String emotion;
  final double confidence;
}

class EmotionChannel {
  static const _channel = EventChannel('com.tuapp.tienda_adaptativa/emotion');

  Stream<EmocionDetectada> get emociones =>
      _channel.receiveBroadcastStream().map((evento) {
        final mapa = evento as Map;
        return EmocionDetectada(
          emotion: mapa['emotion'] as String,
          confidence: (mapa['confidence'] as num).toDouble(),
        );
      });
}
