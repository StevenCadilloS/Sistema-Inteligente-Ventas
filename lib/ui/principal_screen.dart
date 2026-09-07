import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories/cliente_repository.dart';
import '../decision/adaptation_engine.dart';
import '../decision/learning/bandit_optimizer.dart';
import '../services/emotion_channel.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda Adaptativa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/historial'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Deteccion de Emocion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _detectando ? Icons.face : Icons.face_outlined,
                          size: 48,
                          color: _detectando ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emocion: $_emocionDetectada',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              'Confianza: ${(_confianza * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_ofertaActual != null) ...[
              Card(
                color: Colors.deepPurple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Oferta Adaptativa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _ofertaActual!.texto,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.deepPurple.shade200),
                      const SizedBox(height: 8),
                      Text(
                        'Producto: ${_ofertaActual!.producto.nombreProducto}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Precio: S/${(_ofertaActual!.producto.precioUnitarioCentavos / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (_ofertaActual!.estrategia != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Estrategia: ${_ofertaActual!.estrategia!.nombreEstrategia}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
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
                      onPressed: () => _registrarRespuesta(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Me interesa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _registrarRespuesta(false),
                      icon: const Icon(Icons.close),
                      label: const Text('No gracias'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade300,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Esperando deteccion de emocion...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
