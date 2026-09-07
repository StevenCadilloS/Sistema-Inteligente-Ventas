import 'dart:async';

import 'package:flutter/material.dart';

import '../data/database/app_database.dart';
import '../data/repositories/cliente_repository.dart';
import '../decision/adaptation_engine.dart';
import '../decision/learning/bandit_optimizer.dart';
import '../services/emotion_channel.dart';
import '../theme/app_theme.dart';

/// Tienda con feed de productos. La camara corre de fondo (sin preview) y
/// cada vez que cambia la emocion estable del cliente, el feed se reordena y
/// se destaca una oferta nueva — sin que el usuario toque nada, que es el
/// requisito eliminatorio del taller.
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
  List<Producto> _catalogo = const [];
  Oferta? _ofertaActual;
  // null = todavia no llego ninguna emocion estable. Distinto de 'neutral',
  // que si es una lectura real y debe disparar una oferta.
  String? _emocionDetectada;
  double _confianza = 0;
  bool _cargando = true;
  StreamSubscription<EmocionDetectada>? _subscription;

  @override
  void initState() {
    super.initState();
    _cargarCatalogoInicial();
    _iniciarDeteccion();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String? get _codCliente => widget.clienteRepository.clienteActivo();

  /// El feed se pinta desde el arranque con el orden `neutral`, antes de que
  /// la camara detecte nada: la tienda nunca se ve vacia.
  Future<void> _cargarCatalogoInicial() async {
    final codCliente = _codCliente;
    if (codCliente == null) return;

    final catalogo = await widget.adaptationEngine
        .catalogoPara(codCliente: codCliente, emocion: 'neutral');
    if (mounted) {
      setState(() {
        _catalogo = catalogo;
        _cargando = false;
      });
    }
  }

  void _iniciarDeteccion() {
    final codCliente = _codCliente;
    if (codCliente == null) return;

    _subscription = widget.emotionChannel.emociones.listen((emocion) {
      if (!mounted) return;

      final cambioDeEmocion = emocion.emotion != _emocionDetectada;
      setState(() {
        _emocionDetectada = emocion.emotion;
        _confianza = emocion.confidence;
      });

      // Re-decidir en cada frame estable llenaria `interacciones` de filas
      // repetidas; el feed solo reacciona cuando la emocion realmente cambia.
      if (cambioDeEmocion) {
        _adaptarA(emocion, codCliente);
      }
    });
  }

  Future<void> _adaptarA(EmocionDetectada emocion, String codCliente) async {
    try {
      final oferta = await widget.adaptationEngine.decidirOferta(
        codCliente: codCliente,
        emocion: emocion.emotion,
        nivelDeInteres: (emocion.confidence * 100).round(),
      );
      final catalogo = await widget.adaptationEngine
          .catalogoPara(codCliente: codCliente, emocion: emocion.emotion);

      if (mounted) {
        setState(() {
          _ofertaActual = oferta;
          _catalogo = catalogo;
        });
      }
    } catch (e) {
      // Antes esto se perdia en silencio y la pantalla quedaba congelada
      // sin explicacion (p.ej. catalogo vacio).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo adaptar la oferta: $e')),
        );
      }
    }
  }

  /// Compra de un producto que el cliente eligio del feed, no la oferta
  /// sugerida: se registra como su propio proceso de persuasion (sin
  /// estrategia atribuida) y se cierra como venta.
  Future<void> _comprarEleccionLibre(Producto producto) async {
    final codCliente = _codCliente;
    if (codCliente == null) return;

    try {
      final idProceso = await widget.adaptationEngine.registrarEleccionLibre(
        codCliente: codCliente,
        producto: producto,
        emocion: _emocionDetectada ?? 'neutral',
        nivelDeInteres: (_confianza * 100).round(),
      );
      await widget.banditOptimizer
          .registrarRespuesta(idProcesoPersuasion: idProceso, aceptada: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${producto.nombreProducto} agregado a tu compra'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo registrar la compra: $e')),
        );
      }
    }
  }

  void _abrirDetalle(Producto producto) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _DetalleProducto(
        producto: producto,
        onComprar: () {
          Navigator.pop(sheetContext);
          _comprarEleccionLibre(producto);
        },
      ),
    );
  }

  Future<void> _registrarRespuesta(bool aceptada) async {
    final oferta = _ofertaActual;
    if (oferta == null) return;

    await widget.banditOptimizer.registrarRespuesta(
      idProcesoPersuasion: oferta.idProcesoPersuasion,
      aceptada: aceptada,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aceptada ? 'Venta registrada' : 'Oferta descartada'),
          backgroundColor: aceptada ? AppTheme.success : AppTheme.mutedText,
        ),
      );
      setState(() => _ofertaActual = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estilo = EmotionStyle.of(_emocionDetectada ?? 'neutral');
    final detectando = _emocionDetectada != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda Adaptativa'),
        centerTitle: false,
        actions: [
          _ChipEmocion(
            estilo: estilo,
            detectando: detectando,
            confianza: _confianza,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => Navigator.pushNamed(context, '/historial'),
          ),
        ],
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive: 2 columnas en celular, hasta 4 en tablet.
                      final columnas =
                          (constraints.maxWidth / 190).floor().clamp(2, 4);

                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            sliver: SliverToBoxAdapter(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _ofertaActual == null
                                    ? _BannerEsperando(
                                        key: const ValueKey('esperando'),
                                        detectando: detectando,
                                      )
                                    : _OfertaDestacada(
                                        key: ValueKey(
                                            _ofertaActual!.idProcesoPersuasion),
                                        oferta: _ofertaActual!,
                                        estilo: estilo,
                                        onAceptar: () =>
                                            _registrarRespuesta(true),
                                        onRechazar: () =>
                                            _registrarRespuesta(false),
                                      ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            sliver: SliverToBoxAdapter(
                              child: _TituloFeed(
                                estilo: estilo,
                                detectando: detectando,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columnas,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final producto = _catalogo[index];
                                  return _ProductoCard(
                                    key: ValueKey(producto.codLoteProducto),
                                    producto: producto,
                                    destacado: index == 0 && detectando,
                                    estilo: estilo,
                                    onTap: () => _abrirDetalle(producto),
                                  );
                                },
                                childCount: _catalogo.length,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _ChipEmocion extends StatelessWidget {
  const _ChipEmocion({
    required this.estilo,
    required this.detectando,
    required this.confianza,
  });

  final EmotionStyle estilo;
  final bool detectando;
  final double confianza;

  @override
  Widget build(BuildContext context) {
    final color = detectando ? estilo.color : AppTheme.mutedText;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(detectando ? estilo.icon : Icons.videocam_outlined,
                size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              detectando
                  ? '${estilo.label} ${(confianza * 100).toStringAsFixed(0)}%'
                  : 'Leyendo...',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TituloFeed extends StatelessWidget {
  const _TituloFeed({required this.estilo, required this.detectando});

  final EmotionStyle estilo;
  final bool detectando;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Para ti ahora', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          detectando
              ? 'Orden ajustado a tu expresion: ${estilo.label.toLowerCase()}'
              : 'Orden estandar de la tienda',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _BannerEsperando extends StatelessWidget {
  const _BannerEsperando({super.key, required this.detectando});

  final bool detectando;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              detectando ? Icons.auto_awesome : Icons.videocam_outlined,
              color: AppTheme.mutedText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                detectando
                    ? 'Sigue navegando: la oferta se arma sola con tu expresion.'
                    : 'Leyendo tu expresion con la camara frontal...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfertaDestacada extends StatelessWidget {
  const _OfertaDestacada({
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

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: estilo.color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(estilo.icon, size: 18, color: estilo.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Oferta para ti · ${estilo.label}',
                    style: textTheme.titleMedium?.copyWith(color: estilo.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(oferta.texto, style: textTheme.bodyLarge),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    oferta.producto.nombreProducto,
                    style: textTheme.titleMedium,
                  ),
                ),
                Text(
                  'S/$precio',
                  style: textTheme.headlineSmall
                      ?.copyWith(color: AppTheme.success),
                ),
              ],
            ),
            if (oferta.estrategia != null) ...[
              const SizedBox(height: 4),
              Text('Estrategia: ${oferta.estrategia!.nombreEstrategia}',
                  style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAceptar,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Lo quiero'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRechazar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.mutedText,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    child: const Text('Ahora no'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalleProducto extends StatelessWidget {
  const _DetalleProducto({required this.producto, required this.onComprar});

  final Producto producto;
  final VoidCallback onComprar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final precio =
        (producto.precioUnitarioCentavos / 100).toStringAsFixed(2);
    final hayStock = producto.totalDisponible > 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(producto.nombreProducto, style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'S/$precio',
              style: textTheme.headlineMedium?.copyWith(
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hayStock
                  ? '${producto.totalDisponible} disponibles · ${producto.totalVendidos} vendidos'
                  : 'Sin stock por ahora',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: hayStock ? onComprar : null,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(hayStock ? 'Lo quiero' : 'Sin stock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  const _ProductoCard({
    super.key,
    required this.producto,
    required this.destacado,
    required this.estilo,
    required this.onTap,
  });

  final Producto producto;
  final bool destacado;
  final EmotionStyle estilo;
  final VoidCallback onTap;

  /// Sin imagenes en la BD, cada categoria se distingue por color e icono
  /// derivados de su codigo — asi no se rompe si el catalogo cambia.
  (IconData, Color) get _visualCategoria {
    const iconos = [
      Icons.devices_other,
      Icons.chair_outlined,
      Icons.checkroom,
      Icons.spa_outlined,
      Icons.local_mall_outlined,
    ];
    const colores = [
      Color(0xFF0891B2),
      Color(0xFF7C3AED),
      Color(0xFFDB2777),
      Color(0xFF059669),
      Color(0xFFEA580C),
    ];
    final indice = (producto.tipoProducto ?? producto.codLoteProducto)
            .hashCode
            .abs() %
        iconos.length;
    return (iconos[indice], colores[indice]);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icono, color) = _visualCategoria;
    final precio =
        (producto.precioUnitarioCentavos / 100).toStringAsFixed(2);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: destacado ? estilo.color : AppTheme.border,
          width: destacado ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Stack(
                children: [
                  Center(child: Icon(icono, size: 40, color: color)),
                  if (destacado)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: estilo.color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Para ti',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombreProducto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'S/$precio',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppTheme.success,
                  ),
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
