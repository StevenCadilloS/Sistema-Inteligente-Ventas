import 'dart:async';

import 'package:flutter/material.dart';

import '../data/database/app_database.dart';
import '../data/repositories/cliente_repository.dart';
import '../decision/adaptation_engine.dart';
import '../decision/learning/bandit_optimizer.dart';
import '../services/emotion_channel.dart';
import '../theme/app_theme.dart';
import 'widgets/banner_esperando.dart';
import 'widgets/carrito_compras.dart';
import 'widgets/chip_emocion.dart';
import 'widgets/detalle_producto.dart';
import 'widgets/popup_oferta.dart';
import 'widgets/producto_card.dart';
import 'widgets/titulo_feed.dart';

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

class _PrincipalScreenState extends State<PrincipalScreen>
    with SingleTickerProviderStateMixin {
  List<Producto> _catalogo = const [];
  String? _emocionDetectada;
  double _confianza = 0;
  bool _cargando = true;
  StreamSubscription<EmocionDetectada>? _subscription;

  Timer? _ofertaTimer;
  int _segundosRestantes = 0;
  bool _ofertaBloqueada = false;
  OverlayEntry? _overlayEntry;
  bool _emocionCambioDurantePopup = false;
  String? _emocionAntesDelPopup;

  final List<Producto> _carrito = [];

  String? _productoSeleccionadoId;
  Timer? _seleccionTimer;

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
    _seleccionTimer?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  String? get _codCliente => widget.clienteRepository.clienteActivo();

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

      if (_ofertaBloqueada) {
        if (_emocionAntesDelPopup != null && emocion.emotion != _emocionAntesDelPopup) {
          _emocionCambioDurantePopup = true;
        }
        return;
      }

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
    _overlayEntry?.remove();
    _ofertaTimer?.cancel();

    _emocionAntesDelPopup = _emocionDetectada;
    _emocionCambioDurantePopup = false;

    setState(() {
      _ofertaBloqueada = true;
      _segundosRestantes = 10;
    });

    _overlayEntry = OverlayEntry(
      builder: (context) => PopupOferta(
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

    Overlay.of(context).insert(_overlayEntry!);

    _ofertaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _segundosRestantes--;
      });

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

    if (_emocionCambioDurantePopup) {
      _emocionCambioDurantePopup = false;
      _generarOfertaPorEmocion();
    }
  }

  void _generarOfertaPorEmocion() {
    if (_codCliente == null || _catalogo.isEmpty) return;
    final oferta = _crearOferta(_catalogo.first, _emocionDetectada ?? 'neutral');
    _mostrarPopupOferta(oferta.oferta, oferta.mensaje);
  }

  void _abrirDetalle(Producto producto) {
    setState(() {
      _productoSeleccionadoId = producto.codLoteProducto;
    });

    _seleccionTimer?.cancel();
    _seleccionTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _productoSeleccionadoId = null;
        });
      }
    });

    _ofertarProducto(producto);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DetalleProducto(
        producto: producto,
        onComprar: () {
          Navigator.pop(sheetContext);
          _agregarAlCarrito(producto);
        },
      ),
    );
  }

  void _agregarAlCarrito(Producto producto) {
    setState(() {
      _carrito.add(producto);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${producto.nombreProducto} agregado al carrito'),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _abrirCarrito() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => CarritoCompras(
        carrito: _carrito,
        onEliminar: (index) {
          Navigator.pop(sheetContext);
          setState(() {
            _carrito.removeAt(index);
          });
        },
      ),
    );
  }

  void _ofertarProducto(Producto producto) {
    final oferta = _crearOferta(producto, _emocionDetectada ?? 'neutral');
    _mostrarPopupOferta(oferta.oferta, oferta.mensaje);
  }

  /// Crea una oferta basada en la emoción y el producto dado.
  ({Oferta oferta, String mensaje}) _crearOferta(Producto producto, String emocion) {
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
        mensaje = '¡Oferta sorpresa! 15% de descuento solo para ti:';
        break;
      case 'triste':
        tipoOferta = 'sustituto';
        productoSustituto = _buscarSustituto(producto);
        mensaje = 'Veo que no estás muy animado. Mira esta alternativa:';
        break;
      case 'enojo':
        tipoOferta = 'descuento';
        descuentoPorcentaje = 25;
        mensaje = 'Tranquilo, te ofrezco 25% de descuento:';
        break;
      default:
        tipoOferta = 'descuento';
        descuentoPorcentaje = 10;
        mensaje = 'Te tenemos una oferta especial:';
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

    return (
      oferta: Oferta(
        idProcesoPersuasion: 'popup_${DateTime.now().millisecondsSinceEpoch}',
        producto: productoSustituto ?? producto,
        estrategia: null,
        texto: textoOferta,
      ),
      mensaje: mensaje,
    );
  }

  Producto? _buscarSustituto(Producto producto) {
    final mismosTipos = _catalogo
        .where((p) =>
            p.tipoProducto == producto.tipoProducto &&
            p.codLoteProducto != producto.codLoteProducto &&
            p.precioUnitarioCentavos < producto.precioUnitarioCentavos)
        .toList()
      ..sort((a, b) => a.precioUnitarioCentavos.compareTo(b.precioUnitarioCentavos));

    if (mismosTipos.isNotEmpty) return mismosTipos.first;

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
          ChipEmocion(
            estilo: estilo,
            detectando: detectando,
            confianza: _confianza,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'Mi carrito',
                onPressed: _abrirCarrito,
              ),
              if (_carrito.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_carrito.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
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
                      final columnas =
                          (constraints.maxWidth / 190).floor().clamp(2, 4);

                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            sliver: SliverToBoxAdapter(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: BannerEsperando(
                                  key: const ValueKey('esperando'),
                                  detectando: detectando,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            sliver: SliverToBoxAdapter(
                              child: TituloFeed(
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
                                  return ProductoCard(
                                    key: ValueKey(producto.codLoteProducto),
                                    producto: producto,
                                    destacado: index == 0 && detectando,
                                    seleccionado:
                                        _productoSeleccionadoId == producto.codLoteProducto,
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
