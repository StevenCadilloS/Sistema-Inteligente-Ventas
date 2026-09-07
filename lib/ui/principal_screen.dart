import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories/cliente_repository.dart';
import '../decision/adaptation_engine.dart';
import '../decision/learning/bandit_optimizer.dart';
import '../services/emotion_channel.dart';
import '../theme/app_theme.dart';

class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({
    super.key,
    required this.clienteRepository,
    required this.adaptationEngine,
    required this.banditOptimizer,
    required this.emotionChannel,
  });

  final ClienteRepository clienteRepository;
  final AdaptationEngine adaptationEngine;
  final BanditOptimizer banditOptimizer;
  final EmotionChannel emotionChannel;

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  Oferta? _ofertaActual;
  String _emocionDetectada = 'neutral';
  double _confianza = 0.0;
  bool _detectando = false;
  StreamSubscription<EmocionDetectada>? _subscription;

  @override
  void initState() {
    super.initState();
    _iniciarDeteccion();
  }

  void _iniciarDeteccion() {
    final codCliente = widget.clienteRepository.clienteActivo();
    if (codCliente == null) return;

    _subscription = widget.emotionChannel.emociones.listen((emocion) async {
      if (!mounted) return;

      setState(() {
        _emocionDetectada = emocion.emotion;
        _confianza = emocion.confidence;
        _detectando = true;
      });

      final nivelInteres = (emocion.confidence * 100).round();
      final oferta = await widget.adaptationEngine.decidirOferta(
        codCliente: codCliente,
        emocion: emocion.emotion,
        nivelDeInteres: nivelInteres,
      );

      if (mounted) {
        setState(() => _ofertaActual = oferta);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _registrarRespuesta(bool aceptada) async {
    if (_ofertaActual == null) return;

    await widget.banditOptimizer.registrarRespuesta(
      idProcesoPersuasion: _ofertaActual!.idProcesoPersuasion,
      aceptada: aceptada,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aceptada ? 'Venta registrada' : 'Oferta rechazada'),
          backgroundColor: aceptada ? Colors.green : Colors.orange,
        ),
      );
      setState(() => _ofertaActual = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emocionStyle = EmotionStyle.of(_emocionDetectada);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda Adaptativa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => Navigator.pushNamed(context, '/historial'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EmocionCard(
                    detectando: _detectando,
                    confianza: _confianza,
                    estilo: emocionStyle,
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _ofertaActual != null
                        ? _OfertaCard(
                            key: ValueKey(_ofertaActual!.idProcesoPersuasion),
                            oferta: _ofertaActual!,
                            estilo: emocionStyle,
                            onAceptar: () => _registrarRespuesta(true),
                            onRechazar: () => _registrarRespuesta(false),
                          )
                        : const _EsperandoCard(key: ValueKey('esperando')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmocionCard extends StatelessWidget {
  const _EmocionCard({
    required this.detectando,
    required this.confianza,
    required this.estilo,
  });

  final bool detectando;
  final double confianza;
  final EmotionStyle estilo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: detectando
                    ? estilo.color.withValues(alpha: 0.12)
                    : AppTheme.border.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                estilo.icon,
                size: 28,
                color: detectando ? estilo.color : AppTheme.mutedText,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Deteccion de emocion', style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    detectando
                        ? '${estilo.label} · ${(confianza * 100).toStringAsFixed(0)}% confianza'
                        : 'Esperando rostro frente a la camara...',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfertaCard extends StatelessWidget {
  const _OfertaCard({
    super.key,
    required this.oferta,
    required this.estilo,
    required this.onAceptar,
    required this.onRechazar,
  });

  final Oferta oferta;
  final EmotionStyle estilo;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final precio =
        (oferta.producto.precioUnitarioCentavos / 100).toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: estilo.color.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(estilo.icon, color: estilo.color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Oferta adaptativa · ${estilo.label}',
                      style: textTheme.titleMedium?.copyWith(
                        color: estilo.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(oferta.texto, style: textTheme.bodyLarge),
                const SizedBox(height: 12),
                Divider(color: AppTheme.border),
                const SizedBox(height: 8),
                Text(
                  oferta.producto.nombreProducto,
                  style: textTheme.titleMedium,
                ),
                Text(
                  'S/$precio',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppTheme.success,
                  ),
                ),
                if (oferta.estrategia != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Estrategia: ${oferta.estrategia!.nombreEstrategia}',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAceptar,
                icon: const Icon(Icons.check),
                label: const Text('Me interesa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onRechazar,
                icon: const Icon(Icons.close),
                label: const Text('No gracias'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EsperandoCard extends StatelessWidget {
  const _EsperandoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.camera_alt_outlined, size: 56, color: AppTheme.mutedText),
              const SizedBox(height: 16),
              Text(
                'Esperando deteccion de emocion...',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
