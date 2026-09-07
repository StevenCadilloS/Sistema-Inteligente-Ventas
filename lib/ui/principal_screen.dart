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
  String? _emocionDetectada;
  double _confianza = 0;
  bool _cargando = true;
  StreamSubscription<EmocionDetectada>? _subscription;

  // Timer de 10 segundos para la oferta flotante
  Timer? _ofertaTimer;
  int _segundosRestantes = 0;
  bool _ofertaBloqueada = false;
  OverlayEntry? _overlayEntry;
  bool _emocionCambioDurantePopup = false;
  String? _emocionAntesDelPopup;

  @override
  void initState() {
    super.initState();
    _cargarCatalogoInicial();
    _iniciarDeteccion();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ofertaTimer?.cancel();
    _overlayEntry?.remove();
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

    // Si la oferta esta bloqueada (timer de 10 segundos activo),
    // guardamos la emocion y verificamos si cambio.
    if (_ofertaBloqueada) {
      if (_emocionAntesDelPopup != null && emocion.emotion != _emocionAntesDelPopup) {
        _emocionCambioDurantePopup = true;
      }
      return;
    }

      // Re-decidir en cada frame estable llenaria `interacciones` de filas
      // repetidas; el feed solo reacciona cuando la emocion realmente cambia.
      if (cambioDeEmocion) {
        _adaptarA(emocion, codCliente);
      }
    });
  }

  Future<void> _adaptarA(EmocionDetectada emocion, String codCliente) async {
    try {
      final catalogo = await widget.adaptationEngine
          .catalogoPara(codCliente: codCliente, emocion: emocion.emotion);

      if (mounted) {
        setState(() {
          _catalogo = catalogo;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo adaptar el catálogo: $e')),
        );
      }
    }
  }

  void _mostrarPopupOferta(Oferta oferta, String mensaje) {
    // Remover popup anterior si existe
    _overlayEntry?.remove();
    _ofertaTimer?.cancel();

    // Guardar la emocion actual antes de mostrar el popup
    _emocionAntesDelPopup = _emocionDetectada;
    _emocionCambioDurantePopup = false;

    setState(() {
      _ofertaBloqueada = true;
      _segundosRestantes = 10;
    });

    // Crear el overlayEntry
    _overlayEntry = OverlayEntry(
      builder: (context) => _PopupOferta(
        oferta: oferta,
        mensaje: mensaje,
        segundosRestantes: _segundosRestantes,
        onAceptar: () {
          _cerrarPopup();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡${oferta.producto.nombreProducto} agregado!'),
              backgroundColor: AppTheme.success,
            ),
          );
        },
        onRechazar: () {
          _cerrarPopup();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oferta descartada')),
          );
        },
        onCerrar: _cerrarPopup,
      ),
    );

    // Insertar en el overlay
    Overlay.of(context).insert(_overlayEntry!);

    // Iniciar timer de 10 segundos
    _ofertaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _segundosRestantes--;
      });

      // Actualizar el popup con los segundos restantes
      _overlayEntry?.markNeedsBuild();

      if (_segundosRestantes <= 0) {
        _cerrarPopup();
      }
    });
  }

  void _cerrarPopup() {
    _ofertaTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _ofertaBloqueada = false;
    });

    // Si la emocion cambio durante los 10 segundos,
    // generar una nueva oferta con la emocion actual
    if (_emocionCambioDurantePopup) {
      _emocionCambioDurantePopup = false;
      _generarOfertaPorEmocion();
    }
  }

  /// Genera una oferta basada en la ultima emocion detectada por la camara.
  void _generarOfertaPorEmocion() {
    final codCliente = _codCliente;
    if (codCliente == null) return;

    final emocion = _emocionDetectada ?? 'neutral';

    // Buscar un producto aleatorio del catalogo para ofrecer
    if (_catalogo.isEmpty) return;

    final producto = _catalogo.first;

    // Generar tipo de oferta segun emocion
    String tipoOferta;
    String mensaje;
    double? descuentoPorcentaje;
    Producto? productoSustituto;

    switch (emocion) {
      case 'feliz':
        tipoOferta = 'combo';
        mensaje = '¡Veo que te gusta! Te muestro esta nueva opción:';
        break;
      case 'sorpresa':
        tipoOferta = 'descuento';
        descuentoPorcentaje = 15;
        mensaje = '¡Nueva sorpresa! 15% de descuento en esta:';
        break;
      case 'triste':
        tipoOferta = 'sustituto';
        productoSustituto = _buscarSustituto(producto);
        mensaje = 'Veo que cambiaste. Mirá esta alternativa:';
        break;
      case 'enojo':
        tipoOferta = 'descuento';
        descuentoPorcentaje = 25;
        mensaje = 'Tranquilo, te ofrezco algo mejor:';
        break;
      default:
        tipoOferta = 'descuento';
        descuentoPorcentaje = 10;
        mensaje = 'Te tengo otra oferta:';
        break;
    }

    final precio = producto.precioUnitarioCentavos / 100;

    String textoOferta;
    if (tipoOferta == 'combo') {
      final precio2 = (precio * 1.8).toStringAsFixed(2);
      textoOferta = 'Lleva 2 por S/$precio2 (ahorras S/${(precio * 0.2).toStringAsFixed(2)})';
    } else if (tipoOferta == 'sustituto' && productoSustituto != null) {
      final precioSust = (productoSustituto.precioUnitarioCentavos / 100).toStringAsFixed(2);
      textoOferta = '${productoSustituto.nombreProducto} por S/$precioSust';
    } else {
      final precioConDescuento = (precio * (1 - (descuentoPorcentaje ?? 10) / 100)).toStringAsFixed(2);
      textoOferta = 'S/$precioConDescuento (antes S/${precio.toStringAsFixed(2)})';
    }

    final oferta = Oferta(
      idProcesoPersuasion: 'auto_${DateTime.now().millisecondsSinceEpoch}',
      producto: productoSustituto ?? producto,
      estrategia: null,
      texto: textoOferta,
    );

    // Bloquear y mostrar el popup automaticamente
    _mostrarPopupOferta(oferta, mensaje);
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
    // Generar oferta contextual para este producto
    _ofertarProducto(producto);

    // Tambien mostrar el bottom sheet con el detalle
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

  /// Genera una oferta contextual para el producto seleccionado:
  /// descuento, combo o sustituto, dependiendo de la emocion actual.
  void _ofertarProducto(Producto producto) {
    final emocion = _emocionDetectada ?? 'neutral';
    final precio = producto.precioUnitarioCentavos / 100;

    // Generar tipo de oferta segun emocion
    String tipoOferta;
    String mensaje;
    double? descuentoPorcentaje;
    Producto? productoSustituto;

    switch (emocion) {
      case 'feliz':
        // Esta contento → ofrecer combo/lleva 2
        tipoOferta = 'combo';
        mensaje = '¡Me alegra verte así! Lleva 2 por un precio especial:';
        break;
      case 'sorpresa':
        // Sorprendido → descuento exclusivo
        tipoOferta = 'descuento';
        descuentoPorcentaje = 15;
        mensaje = '¡Oferta sorpresa! 15% de descuento solo para ti:';
        break;
      case 'triste':
        // Triste → sustituto mas economico
        tipoOferta = 'sustituto';
        productoSustituto = _buscarSustituto(producto);
        mensaje = 'Veo que no estás muy animado. Mira esta alternativa:';
        break;
      case 'enojo':
        // Enojado → descuento fuerte para calmar
        tipoOferta = 'descuento';
        descuentoPorcentaje = 25;
        mensaje = 'Tranquilo, te ofrezco 25% de descuento:';
        break;
      default:
        // Neutral → descuento standard
        tipoOferta = 'descuento';
        descuentoPorcentaje = 10;
        mensaje = 'Te tenemos una oferta especial:';
        break;
    }

    // Construir texto de la oferta
    String textoOferta;
    if (tipoOferta == 'combo') {
      final precio2 = (precio * 1.8).toStringAsFixed(2);
      textoOferta = 'Lleva 2 por S/$precio2 (ahorras S/${(precio * 0.2).toStringAsFixed(2)})';
    } else if (tipoOferta == 'sustituto' && productoSustituto != null) {
      final precioSust = (productoSustituto.precioUnitarioCentavos / 100).toStringAsFixed(2);
      textoOferta = '${productoSustituto.nombreProducto} por S/$precioSust';
    } else {
      final precioConDescuento = (precio * (1 - (descuentoPorcentaje ?? 10) / 100)).toStringAsFixed(2);
      textoOferta = 'S/$precioConDescuento (antes S/${precio.toStringAsFixed(2)})';
    }

    // Creer una oferta fake para el popup
    final oferta = Oferta(
      idProcesoPersuasion: 'popup_${DateTime.now().millisecondsSinceEpoch}',
      producto: productoSustituto ?? producto,
      estrategia: null,
      texto: textoOferta,
    );

    // Mostrar popup con la oferta contextual
    _mostrarPopupOferta(oferta, mensaje);
  }

  /// Busca un sustituto mas economico en el catalogo
  Producto? _buscarSustituto(Producto producto) {
    // Buscar productos de la misma categoria mas baratos
    final mismosTipos = _catalogo
        .where((p) =>
            p.tipoProducto == producto.tipoProducto &&
            p.codLoteProducto != producto.codLoteProducto &&
            p.precioUnitarioCentavos < producto.precioUnitarioCentavos)
        .toList()
      ..sort((a, b) => a.precioUnitarioCentavos.compareTo(b.precioUnitarioCentavos));

    if (mismosTipos.isNotEmpty) return mismosTipos.first;

    // Si no hay de la misma categoria, buscar el mas barato en general
    final todosOrdenados = List<Producto>.from(_catalogo)
      ..sort((a, b) => a.precioUnitarioCentavos.compareTo(b.precioUnitarioCentavos));

    return todosOrdenados.isNotEmpty ? todosOrdenados.first : null;
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
                                child: _BannerEsperando(
                                        key: const ValueKey('esperando'),
                                        detectando: detectando,
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

/// Popup flotante que muestra la oferta durante 10 segundos.
/// Aparece centrado en la pantalla con un timer visible.
class _PopupOferta extends StatelessWidget {
  const _PopupOferta({
    required this.oferta,
    required this.mensaje,
    required this.segundosRestantes,
    required this.onAceptar,
    required this.onRechazar,
    required this.onCerrar,
  });

  final Oferta oferta;
  final String mensaje;
  final int segundosRestantes;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final precio =
        (oferta.producto.precioUnitarioCentavos / 100).toStringAsFixed(2);
    final estilo = EmotionStyle.of('neutral');

    return Stack(
      children: [
        // Fondo oscuro semitransparente
        GestureDetector(
          onTap: onCerrar,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        // Popup centrado
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timer y boton cerrar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 16, color: AppTheme.success),
                            const SizedBox(width: 4),
                            Text(
                              '${segundosRestantes}s',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onCerrar,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Mensaje contextual
                  Text(
                    mensaje,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedText,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Icono de emocion
                  Icon(estilo.icon, size: 32, color: estilo.color),
                  const SizedBox(height: 12),
                  // Nombre del producto
                  Text(
                    oferta.producto.nombreProducto,
                    style: textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Precio
                  Text(
                    'S/$precio',
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Texto de la oferta
                  Text(
                    oferta.texto,
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (oferta.estrategia != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Estrategia: ${oferta.estrategia!.nombreEstrategia}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Botones de accion
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRechazar,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.mutedText,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
          ),
        ),
      ],
    );
  }
}
