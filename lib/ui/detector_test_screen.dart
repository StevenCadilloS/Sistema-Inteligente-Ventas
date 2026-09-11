import 'dart:async';

import 'package:flutter/material.dart';

import '../services/emotion_channel.dart';
import '../theme/app_theme.dart';

/// Aplicacion independiente para probar el detector sin iniciar Supabase.
class DetectorTestApp extends StatelessWidget {
  const DetectorTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prueba del detector',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const DetectorTestScreen(emotionChannel: EmotionChannel()),
    );
  }
}

/// Diagnostico local: la imagen y las mediciones nunca salen del telefono.
class DetectorTestScreen extends StatefulWidget {
  const DetectorTestScreen({
    super.key,
    required this.emotionChannel,
  });

  final EmotionChannel emotionChannel;

  @override
  State<DetectorTestScreen> createState() => _DetectorTestScreenState();
}

class _DetectorTestScreenState extends State<DetectorTestScreen> {
  StreamSubscription<EmocionDetectada>? _subscription;
  EmocionDetectada? _lectura;
  String? _error;
  bool _leyendo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _comenzar());
  }

  Future<void> _comenzar() async {
    if (!widget.emotionChannel.disponible || _leyendo) return;

    setState(() {
      _leyendo = true;
      _error = null;
    });
    _subscription = widget.emotionChannel.diagnostico.listen(
      (lectura) {
        if (!mounted) return;
        setState(() => _lectura = lectura);
      },
      onError: (Object error) {
        if (!mounted) return;
        _subscription?.cancel();
        _subscription = null;
        setState(() {
          _error = 'Camara bloqueada. Ve a Ajustes > Aplicaciones > '
              'Tienda Adaptativa > Permisos y habilita Camara.';
          _leyendo = false;
        });
      },
    );
  }

  Future<void> _detener() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!mounted) return;
    setState(() {
      _leyendo = false;
      _lectura = null;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lectura = _lectura;
    final estilo = EmotionStyle.of(lectura?.emotion ?? 'neutral');

    return Scaffold(
      appBar: AppBar(title: const Text('Prueba del detector')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.emotionChannel.disponible)
                      const AndroidView(
                        viewType:
                            'com.tuapp.tienda_adaptativa/emotion_preview',
                      )
                    else
                      const _PlataformaNoCompatible(),
                    Center(
                      child: IgnorePointer(
                        child: Container(
                          width: 220,
                          height: 280,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: estilo.color,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(110),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _IndicadorLocal(leyendo: _leyendo),
                    ),
                  ],
                ),
              ),
            ),
            _PanelLectura(
              lectura: lectura,
              estilo: estilo,
              error: _error,
              leyendo: _leyendo,
              onToggle: _leyendo ? _detener : _comenzar,
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelLectura extends StatelessWidget {
  const _PanelLectura({
    required this.lectura,
    required this.estilo,
    required this.error,
    required this.leyendo,
    required this.onToggle,
  });

  final EmocionDetectada? lectura;
  final EmotionStyle estilo;
  final String? error;
  final bool leyendo;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final probabilidad = lectura?.smileProbability;
    final mensaje = error ?? _mensajeEstado(lectura?.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(estilo.icon, color: estilo.color, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lectura == null ? 'Preparando detector…' : estilo.label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: estilo.color,
                      ),
                    ),
                    Text(mensaje),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metrica(
                  etiqueta: 'Sonrisa',
                  valor: probabilidad == null
                      ? '—'
                      : '${(probabilidad * 100).round()}%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metrica(
                  etiqueta: 'Confianza',
                  valor: lectura == null
                      ? '—'
                      : '${(lectura!.confidence * 100).round()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onToggle,
            icon: Icon(leyendo ? Icons.stop_circle_outlined : Icons.play_arrow),
            label: Text(leyendo ? 'Detener prueba' : 'Iniciar prueba'),
          ),
          const SizedBox(height: 8),
          const Text(
            'La camara se procesa localmente. No se guardan ni se envian imagenes.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _mensajeEstado(String? status) {
    return switch (status) {
      'no_face' => 'Coloca el rostro dentro del ovalo.',
      'face_too_small' => 'Acercate un poco a la camara.',
      'bad_angle' => 'Mira de frente y mantén la cabeza recta.',
      'no_smile_probability' => 'No se pudo medir la expresion. Mejora la luz.',
      'ambiguous' => 'La lectura esta entre ambos umbrales.',
      'ok' => 'Lectura valida en tiempo real.',
      _ => 'Esperando una lectura facial…',
    };
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(etiqueta, style: Theme.of(context).textTheme.bodyMedium),
          Text(valor, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _IndicadorLocal extends StatelessWidget {
  const _IndicadorLocal({required this.leyendo});

  final bool leyendo;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              leyendo ? Icons.circle : Icons.pause_circle,
              size: 10,
              color: leyendo ? Colors.greenAccent : Colors.white70,
            ),
            const SizedBox(width: 7),
            Text(
              leyendo ? 'ANALISIS LOCAL' : 'PAUSADO',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlataformaNoCompatible extends StatelessWidget {
  const _PlataformaNoCompatible();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'El detector esta disponible en Android.',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
