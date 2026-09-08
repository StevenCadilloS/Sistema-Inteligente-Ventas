import 'dart:async';

import 'package:flutter/material.dart';

import '../data/database/app_database.dart';
import '../data/repositories/cliente_repository.dart';
import '../decision/adaptation_engine.dart';
import '../decision/learning/bandit_optimizer.dart';
import '../services/emotion_channel.dart';
import '../theme/app_theme.dart';
import 'widgets/banner_esperando.dart';
import 'widgets/compras_realizadas.dart';
import 'widgets/chip_emocion.dart';
import 'widgets/popup_oferta.dart';
import 'widgets/producto_card.dart';
import 'widgets/titulo_feed.dart';

/// Tienda con feed de productos. La camara corre de fondo (sin preview) y
/// cada vez que cambia la emocion estable del cliente, el feed se reordena y
/// se destaca una oferta nueva — sin que el usuario toque nada, que es el
/// requisito eliminatorio del taller.
class TiendaScreen extends StatefulWidget {
  const TiendaScreen({
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
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen>
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

  /// Compras cerradas en esta sesion, con lo realmente pagado por cada una.
  final List<CompraRealizada> _compras = [];

  /// Productos que el cliente ya rechazo: la siguiente oferta los salta.
  final Set<String> _rechazados = {};

  /// Producto de la oferta abierta, para reofrecerlo con mejor descuento si
  /// la expresion del cliente cambia mientras la mira.
  Producto? _productoEnOferta;

  /// Paso de la negociacion en curso: 0 precio de lista, 1 contraoferta con
  /// descuento, 2 bien sustituto. Es un contador explicito y no se deduce del
  /// descuento de la oferta, porque hay estrategias (envio gratis, premium)
  /// que persuaden sin tocar el precio: inferirlo dejaria la escalada en
  /// bucle sobre el mismo paso.
  int _pasoNegociacion = 0;

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

    final catalogo = await widget.adaptationEngine.catalogoPara(
      codCliente: codCliente,
      emocion: 'neutral',
    );
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

      // El rostro salio de cuadro: el chip vuelve a "Leyendo..." en vez de
      // quedarse congelado con la ultima emocion detectada.
      if (emocion.emotion == 'no_face') {
        setState(() {
          _emocionDetectada = null;
          _confianza = 0;
        });
        return;
      }

      final cambioDeEmocion = emocion.emotion != _emocionDetectada;
      setState(() {
        _emocionDetectada = emocion.emotion;
        _confianza = emocion.confidence;
      });

      if (_ofertaBloqueada) {
        if (_emocionAntesDelPopup != null &&
            emocion.emotion != _emocionAntesDelPopup) {
          _emocionCambioDurantePopup = true;
        }
        return;
      }

      if (cambioDeEmocion) {
        // Lo que no quiso estando enojado puede quererlo contento: los
        // rechazos se olvidan al cambiar de expresion.
        _rechazados.clear();
        _adaptarA(emocion, codCliente);
      }
    });
  }

  Future<void> _adaptarA(EmocionDetectada emocion, String codCliente) async {
    try {
      final catalogo = await widget.adaptationEngine.catalogoPara(
        codCliente: codCliente,
        emocion: emocion.emotion,
      );

      // El feed se reordena solo al cambiar la emocion, sin que el cliente
      // toque nada: esa es la adaptacion automatica que exige el taller. La
      // oferta no se dispara aqui — interrumpir cada cambio de cara es
      // molesto; nace cuando el cliente toca un producto (ver
      // [_seleccionarProducto]).
      if (!mounted) return;
      setState(() {
        _catalogo = catalogo;
      });
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
    _productoEnOferta = oferta.producto;

    setState(() {
      _ofertaBloqueada = true;
      _segundosRestantes = 10;
    });

    _overlayEntry = _construirOverlay(oferta, mensaje);
    Overlay.of(context).insert(_overlayEntry!);
    _iniciarCuentaRegresiva();
  }

  OverlayEntry _construirOverlay(Oferta oferta, String mensaje) {
    return OverlayEntry(
      builder: (context) => PopupOferta(
        oferta: oferta,
        mensaje: mensaje,
        segundosRestantes: _segundosRestantes,
        onAceptar: () {
          _cerrarPopup();
          _responderOferta(oferta, aceptada: true);
        },
        onRechazar: () {
          _cerrarPopup();
          _responderOferta(oferta, aceptada: false);
        },
        onCerrar: _cerrarPopup,
      ),
    );
  }

  /// La oferta caduca a los 10 segundos. Sin esto se queda abierta bloqueando
  /// la tienda si el cliente no responde nada.
  void _iniciarCuentaRegresiva() {
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
        _cerrarPopup(porTimeout: true);
      }
    });
  }

  /// Cierra la oferta abierta.
  ///
  /// [porTimeout] distingue quien cerro: si se agotaron los 10 segundos el
  /// cliente no respondio nada, y ahi si vale mejorarle el precio cuando su
  /// expresion cambio mientras miraba. Si fue el quien cerro — la X, el fondo,
  /// "lo quiero" o "no, gracias" — reabrir la oferta es un bucle: cerraba y
  /// volvia a salir, sin salida posible.
  void _cerrarPopup({bool porTimeout = false}) {
    _ofertaTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _ofertaBloqueada = false;
    });

    final producto = _productoEnOferta;
    // La mejora por cambio de expresion es un peldano mas de la escalera, no
    // una via paralela: consume el paso 0 -> 1 y por eso termina, igual que
    // el rechazo explicito.
    final mejorar =
        porTimeout &&
        _emocionCambioDurantePopup &&
        _pasoNegociacion == 0 &&
        producto != null;

    _emocionCambioDurantePopup = false;
    _emocionAntesDelPopup = null;

    if (!mejorar) {
      _productoEnOferta = null;
      return;
    }

    _pasoNegociacion = 1;
    _ofertarRetencion(
      producto,
      conDescuento: true,
      mensaje: 'Veo que lo dudas, te mejoro el precio:',
    );
  }

  /// Cierra el proceso de persuasion. Aceptar crea la venta con el precio
  /// realmente ofrecido (con descuento); rechazar no escribe nada, porque la
  /// ausencia de venta para ese idProcesoPersuasion *es* el rechazo — asi lo
  /// mide el KPI 2 (ver queries.drift).
  Future<void> _responderOferta(Oferta oferta, {required bool aceptada}) async {
    try {
      await widget.banditOptimizer.registrarRespuesta(
        idProcesoPersuasion: oferta.idProcesoPersuasion,
        aceptada: aceptada,
        precioFinalCentavos: oferta.precioFinalCentavos,
      );

      if (!mounted) return;
      if (aceptada) {
        _registrarCompra(oferta.producto, oferta.precioFinalCentavos);
        return;
      }

      await _siguientePeldano(oferta);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo registrar la respuesta: $e')),
        );
      }
    }
  }

  /// Escalada tras un rechazo: precio de lista -> precio rebajado -> bien
  /// sustituto -> dejar de insistir.
  ///
  /// El peldano vive en [_pasoNegociacion] y solo avanza, nunca retrocede: por
  /// eso la escalada siempre termina, aunque el cliente rechace todo.
  Future<void> _siguientePeldano(Oferta oferta) async {
    // Dijo que no a precio de lista: se responde con la mejor oferta que
    // permitan su expresion y la estrategia elegida.
    if (_pasoNegociacion == 0) {
      _pasoNegociacion = 1;
      await _ofertarTrasPausa(oferta.producto);
      return;
    }

    // Rechazo tambien el precio rebajado. Cada intento quedo registrado como
    // su propio proceso de persuasion, que es lo que alimenta al UCB1.
    _rechazados.add(oferta.producto.codLoteProducto);

    if (_pasoNegociacion == 1 && await _ofrecerSustituto(oferta.producto)) {
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listo, te dejamos seguir mirando')),
      );
    }
  }

  /// Insistir con lo que ya rechazo dos veces no tiene sentido, pero si
  /// ofrecerle otra cosa de su misma categoria y mas economica.
  ///
  /// Devuelve si habia sustituto que ofrecer; si no, la negociacion termina.
  Future<bool> _ofrecerSustituto(Producto rechazado) async {
    final sustituto = await widget.adaptationEngine.sustitutoPara(
      rechazado,
      excluir: {
        ..._rechazados,
        ..._compras.map((c) => c.producto.codLoteProducto),
      },
    );
    if (sustituto == null || !mounted || _ofertaBloqueada) return false;

    _pasoNegociacion = 2;
    await _ofertarTrasPausa(sustituto, mensaje: 'Quiza este te acomode mejor:');
    return true;
  }

  /// Medio segundo entre el rechazo y la oferta siguiente: encadenarlas sin
  /// pausa se ve como un parpadeo del popup, no como una respuesta.
  Future<void> _ofertarTrasPausa(Producto producto, {String? mensaje}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _ofertaBloqueada) return;
    await _ofertarRetencion(producto, conDescuento: true, mensaje: mensaje);
  }

  bool _yaComprado(Producto producto) => _compras.any(
    (c) => c.producto.codLoteProducto == producto.codLoteProducto,
  );

  /// Tocar un producto es la senal de interes: se le propone de inmediato, a
  /// precio de lista. Si dice que no, ahi entra el descuento segun su cara.
  Future<void> _seleccionarProducto(Producto producto) async {
    // Lo que ya compro sale del circuito de ofertas: insistir con el mismo
    // producto terminaba vendiendoselo dos veces el mismo dia, y la segunda
    // mas barata que la primera.
    if (_yaComprado(producto)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ya compraste ${producto.nombreProducto}')),
      );
      return;
    }

    _pasoNegociacion = 0;

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

    await _ofertarRetencion(producto);
  }

  /// Oferta sobre el producto que el cliente acaba de mostrar interes.
  ///
  /// [conDescuento] escala la negociacion: la primera va a precio de lista, y
  /// solo si dice que no se le mejora el precio segun su expresion.
  Future<void> _ofertarRetencion(
    Producto producto, {
    bool conDescuento = false,
    String? mensaje,
  }) async {
    final codCliente = _codCliente;
    if (codCliente == null || _ofertaBloqueada || _yaComprado(producto)) return;

    try {
      final oferta = await widget.adaptationEngine.decidirOferta(
        codCliente: codCliente,
        emocion: _emocionDetectada ?? 'neutral',
        nivelDeInteres: (_confianza * 100).round(),
        productoObjetivo: producto,
        conDescuento: conDescuento,
      );
      final texto =
          mensaje ??
          (oferta.tieneDescuento
              ? 'Espera, te mejoro el precio:'
              : '¿Te lo llevas?');
      if (mounted) _mostrarPopupOferta(oferta, texto);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar la oferta: $e')),
        );
      }
    }
  }

  void _registrarCompra(Producto producto, int pagadoCentavos) {
    setState(() {
      _compras.add((producto: producto, pagadoCentavos: pagadoCentavos));
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
      builder: (sheetContext) => ComprasRealizadas(compras: _compras),
    );
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
              if (_compras.isNotEmpty)
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
                      '${_compras.length}',
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
                      final columnas = (constraints.maxWidth / 190)
                          .floor()
                          .clamp(2, 4);

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
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final producto = _catalogo[index];
                                return ProductoCard(
                                  key: ValueKey(producto.codLoteProducto),
                                  producto: producto,
                                  destacado: index == 0 && detectando,
                                  seleccionado:
                                      _productoSeleccionadoId ==
                                      producto.codLoteProducto,
                                  comprado: _yaComprado(producto),
                                  estilo: estilo,
                                  onTap: () => _seleccionarProducto(producto),
                                );
                              }, childCount: _catalogo.length),
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
