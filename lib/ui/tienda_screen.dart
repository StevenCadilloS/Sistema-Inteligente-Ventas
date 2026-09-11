import 'dart:async';

import 'package:flutter/material.dart';

import '../data/modelos/modelos.dart';
import '../data/remote/sesion_service.dart';
import '../data/repositories/tienda_repository.dart';
import '../decision/negociacion.dart';
import '../services/emotion_channel.dart';
import '../theme/app_theme.dart';
import 'widgets/banner_esperando.dart';
import 'widgets/chip_emocion.dart';
import 'widgets/compras_realizadas.dart';
import 'widgets/popup_oferta.dart';
import 'widgets/producto_card.dart';
import 'widgets/titulo_feed.dart';

/// Pantalla principal de la tienda.
///
/// El flujo es el del README: el cliente navega el catalogo con la camara
/// APAGADA; al seleccionar un producto empieza la interaccion adaptativa, se
/// enciende la camara, se muestra el precio normal y se observa su respuesta.
/// Si es desfavorable se avanza por la escalera de ofertas que configuro el
/// administrador. Al terminar — compra, abandono o fin de la escalera — la
/// camara se apaga.
///
/// La camara no sigue encendida durante toda la navegacion, y eso no es solo
/// bateria: mantener la camara viva mientras alguien mira un catalogo es
/// bastante mas invasivo que encenderla para una negociacion concreta.
class TiendaScreen extends StatefulWidget {
  const TiendaScreen({
    super.key,
    required this.sesion,
    required this.emotionChannel,
    required this.tienda,
    this.clasificador = const ClasificadorRespuesta(),
    this.ventanaObservacion = const Duration(seconds: 8),
  });

  final SesionService sesion;
  final EmotionChannel emotionChannel;
  final TiendaRepository tienda;

  /// Como se agrupan las lecturas de la camara en una respuesta.
  final ClasificadorRespuesta clasificador;

  /// Cuanto se observa antes de decidir.
  ///
  /// El modulo nativo no entrega una lectura por frame: EmotionProcessor exige
  /// 26 frames consecutivos de la misma emocion antes de declararla estable, y
  /// a ~20 fps eso es ~1,3 s por lectura — mas si el rostro se mueve y el
  /// contador se reinicia. Con una ventana de 4 s apenas caben dos, y en
  /// condiciones reales a veces ninguna: la ventana se cerraba sin votos, el
  /// clasificador devolvia sinSenal y la escalera no avanzaba nunca.
  ///
  /// 8 s deja sitio para 4-5 lecturas estables, que es lo que el clasificador
  /// necesita para decidir por mayoria y no por casualidad.
  final Duration ventanaObservacion;

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  List<Producto> _catalogo = const [];
  bool _cargando = true;
  String? _errorCatalogo;
  StreamSubscription<List<Producto>>? _catalogoSubscription;

  // --------------- ESTADO DE LA INTERACCION ---------------
  //
  // Todo esto solo existe mientras hay una negociacion abierta.

  Negociacion? _negociacion;
  StreamSubscription<EmocionDetectada>? _emociones;
  Timer? _ventana;

  /// Lecturas de la camara en la ventana en curso. Se vacia en cada ronda.
  final List<String> _lecturas = [];

  String? _emocionDetectada;
  double _confianza = 0;
  OverlayEntry? _overlay;

  /// Compras cerradas en esta sesion, con lo realmente pagado por cada una.
  final List<CompraRealizada> _compras = [];

  /// Hay sesion pero falta la ficha de cliente. Se puede mirar el catalogo,
  /// no comprar.
  bool _sinFicha = false;

  @override
  void initState() {
    super.initState();
    _escucharCatalogo();
    _comprobarFicha();
  }

  /// Hay sesion, pero puede no haber ficha de cliente: pasa si la app se
  /// cerro justo despues de confirmar el correo, o si la cuenta se creo desde
  /// otro dispositivo. Sin ficha, fn_cliente_actual() devuelve null y la
  /// tienda no podria ni ofertar ni vender — mejor detectarlo al entrar que
  /// cuando el cliente ya eligio un producto.
  Future<void> _comprobarFicha() async {
    try {
      final id = await widget.tienda.clienteActual();
      if (!mounted) return;
      setState(() => _sinFicha = id == null);
    } catch (_) {
      // Un fallo de red aqui no debe bloquear la tienda: el catalogo se lee
      // igual, y al comprar el servidor volveria a decir que falta sesion.
    }
  }

  @override
  void dispose() {
    _catalogoSubscription?.cancel();
    _terminarInteraccion(); // apaga la camara y cierra el popup
    super.dispose();
  }

  bool get _negociando => _negociacion != null;

  bool get _camaraEncendida => _emociones != null;

  // --------------- CATALOGO ---------------

  /// El catalogo llega del servidor y se vuelve a emitir cada vez que el
  /// administrador cambia un producto, su stock o una oferta. No hay boton de
  /// refrescar: si alguien vende la ultima unidad, el feed de todos se entera
  /// solo.
  void _escucharCatalogo() {
    _catalogoSubscription = widget.tienda.observarCatalogo().listen(
      (productos) {
        if (!mounted) return;
        setState(() {
          _catalogo = productos;
          _cargando = false;
          _errorCatalogo = null;
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _cargando = false;
          _errorCatalogo = e.toString();
        });
      },
    );
  }

  // --------------- INTERACCION ADAPTATIVA ---------------

  /// El cliente selecciono un producto: empieza la interaccion.
  ///
  /// Se pide la escalera antes de encender la camara. Si viene vacia — sin
  /// ofertas configuradas, ninguna vigente, o el cliente sin cupo — no hay
  /// nada que negociar y se ofrece a precio normal sin encender nada.
  Future<void> _seleccionarProducto(Producto producto) async {
    if (_negociando) return;

    if (_sinFicha) {
      _avisar('Completa tu registro para poder comprar.');
      return;
    }

    if (_yaComprado(producto)) {
      _avisar('Ya compraste ${producto.nombre} en esta sesion.');
      return;
    }

    List<EscalonOferta> escalera;
    try {
      escalera = await widget.tienda.ofertasDe(producto.idProducto);
    } on SinSesionException {
      if (!mounted) return;
      _volverAlLogin();
      return;
    } catch (e) {
      if (!mounted) return;
      _avisar('No se pudieron consultar las ofertas: $e');
      return;
    }

    if (!mounted) return;

    final negociacion = Negociacion(producto: producto, escalera: escalera);
    setState(() => _negociacion = negociacion);
    _mostrarPopup();

    // Sin escalera no hay nada que observar: se muestra el precio normal y se
    // deja al cliente decidir, con la camara apagada.
    if (escalera.isEmpty) return;

    // Sin detector (web, escritorio) tampoco: la oferta se queda en el precio
    // normal, que es lo que corresponde cuando no hay senal que interpretar.
    // Abrir la ventana igual dejaria al cliente esperando una evaluacion que
    // nunca llega.
    if (!widget.emotionChannel.disponible) return;

    _encenderCamara();
    _abrirVentana();
  }

  void _encenderCamara() {
    _emociones = widget.emotionChannel.emociones.listen(
      (e) {
      if (!mounted) return;

      if (e.emotion == 'no_face') {
        // El rostro salio de cuadro: el chip vuelve a "Leyendo..." en vez de
        // quedarse congelado con la ultima emocion.
        setState(() {
          _emocionDetectada = null;
          _confianza = 0;
        });
        return;
      }

        _lecturas.add(e.emotion);
        setState(() {
          _emocionDetectada = e.emotion;
          _confianza = e.confidence;
        });
        _refrescarPopup();
      },
      // El modulo nativo avisa por aqui si no puede abrir la camara: permiso
      // denegado, o la tiene otra app. Sin esto la ventana se abria igual y el
      // cliente esperaba 8 segundos una evaluacion que no iba a llegar nunca.
      onError: (Object e) {
        if (!mounted) return;
        _apagarCamara();
        _refrescarPopup();
        _avisar(
          'Sin camara, la oferta se queda en el precio normal. '
          'Puedes seguir con el boton.',
        );
      },
    );
  }

  /// Abre una ventana de observacion. Al cerrarse se clasifica lo leido y se
  /// decide si mantener el precio o avanzar de escalon.
  void _abrirVentana() {
    _lecturas.clear();
    _ventana?.cancel();
    _ventana = Timer(widget.ventanaObservacion, _evaluarVentana);
  }

  void _evaluarVentana() {
    final negociacion = _negociacion;
    if (negociacion == null || !mounted) return;

    final respuesta = widget.clasificador.clasificar(_lecturas);

    switch (negociacion.siguientePaso(respuesta)) {
      case PasoNegociacion.mantener:
        // Se queda donde esta y se sigue observando: el cliente puede cambiar
        // de opinion mientras mira.
        _abrirVentana();

      case PasoNegociacion.avanzar:
        negociacion.avanzar();
        setState(() {});
        _refrescarPopup();
        _abrirVentana();

      case PasoNegociacion.terminar:
        // No quedan ofertas. Se deja la ultima en pantalla y se apaga la
        // camara: seguir mirando una cara que ya no puede cambiar nada solo
        // gasta bateria.
        _apagarCamara();
    }
  }

  // --------------- POPUP ---------------

  void _mostrarPopup() {
    _overlay?.remove();
    _overlay = OverlayEntry(builder: (_) => _construirPopup());
    Overlay.of(context).insert(_overlay!);
  }

  void _refrescarPopup() => _overlay?.markNeedsBuild();

  Widget _construirPopup() {
    final negociacion = _negociacion;
    if (negociacion == null) return const SizedBox.shrink();

    return PopupOferta(
      negociacion: negociacion,
      mensaje: negociacion.mensaje,
      // Lecturas estables acumuladas en la ventana en curso. Sin esto no hay
      // forma de distinguir "observando" de "colgado": el detector tarda ~1,3s
      // por lectura y no imprime nada. -1 significa que no hay camara.
      lecturas: _camaraEncendida ? _lecturas.length : -1,
      onAceptar: () => _comprar(negociacion),
      onRechazar: () => _rechazar(negociacion),
      onCerrar: _terminarInteraccion,
    );
  }

  /// El cliente dijo que no a la oferta que tiene delante.
  ///
  /// Rechazar es una respuesta desfavorable explicita, asi que hace lo mismo
  /// que una cara desfavorable: avanzar al siguiente escalon. Solo cuando la
  /// escalera se acaba termina la interaccion — antes, el boton cerraba todo
  /// al primer "no" y el cliente nunca llegaba a ver la segunda oferta.
  ///
  /// La ventana de observacion se reinicia: si la camara estaba a mitad de
  /// una ronda, esa lectura ya no corresponde a lo que se muestra ahora.
  void _rechazar(Negociacion negociacion) {
    if (!negociacion.quedanEscalones) {
      _avisar('No quedan mas ofertas para ${negociacion.producto.nombre}.');
      _terminarInteraccion();
      return;
    }

    negociacion.avanzar();
    setState(() {});
    _refrescarPopup();
    if (_camaraEncendida) _abrirVentana();
  }

  // --------------- CIERRE ---------------

  Future<void> _comprar(Negociacion negociacion) async {
    final pagado = negociacion.precioActualCentavos;
    final producto = negociacion.producto;

    // La camara se apaga antes de la llamada: la decision ya esta tomada y
    // seguir leyendo la cara mientras se registra la venta no sirve de nada.
    _apagarCamara();

    try {
      await widget.tienda.registrarVenta(
        idProducto: producto.idProducto,
        idOferta: negociacion.idOfertaActual,
      );
    } on SinStockException {
      if (!mounted) return;
      _terminarInteraccion();
      _avisar('Alguien se llevo la ultima unidad de ${producto.nombre}.');
      return;
    } on LimiteOfertasException {
      if (!mounted) return;
      _terminarInteraccion();
      _avisar(
        'Ya usaste tus dos ofertas de hoy. Puedes comprarlo a precio normal.',
      );
      return;
    } on SinSesionException {
      // La sesion caduco mientras negociaba. Se vuelve al login en vez de
      // dejarlo pulsando un boton que ya no puede funcionar.
      if (!mounted) return;
      _terminarInteraccion();
      _volverAlLogin();
      return;
    } catch (e) {
      if (!mounted) return;
      _terminarInteraccion();
      _avisar('No se pudo completar la compra: $e');
      return;
    }

    if (!mounted) return;
    setState(() {
      _compras.add((producto: producto, pagadoCentavos: pagado));
    });
    _terminarInteraccion();
    _avisar('Compraste ${producto.nombre} por ${soles(pagado)}.');
  }

  /// Termina la interaccion: apaga la camara, cierra el popup y olvida la
  /// negociacion. Se llama tanto al comprar como al abandonar.
  void _terminarInteraccion() {
    _apagarCamara();
    _overlay?.remove();
    _overlay = null;
    if (mounted) {
      setState(() => _negociacion = null);
    } else {
      _negociacion = null;
    }
  }

  void _apagarCamara() {
    _ventana?.cancel();
    _ventana = null;
    _emociones?.cancel();
    _emociones = null;
    _lecturas.clear();
    if (mounted) {
      setState(() {
        _emocionDetectada = null;
        _confianza = 0;
      });
    }
  }

  // --------------- AYUDAS ---------------

  bool _yaComprado(Producto producto) =>
      _compras.any((c) => c.producto.idProducto == producto.idProducto);

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _volverAlLogin() {
    _avisar('Tu sesion expiro. Vuelve a ingresar.');
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  Future<void> _cerrarSesion() async {
    _terminarInteraccion();
    await widget.sesion.cerrarSesion();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  void _abrirCarrito() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ComprasRealizadas(compras: _compras),
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
          // El chip solo aparece durante una negociacion: fuera de ella la
          // camara esta apagada y anunciar una emocion seria mentira.
          if (_negociando)
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
            tooltip: 'Mis compras',
            onPressed: () => Navigator.pushNamed(context, '/historial'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: SafeArea(child: _cuerpo(estilo, detectando)),
    );
  }

  Widget _cuerpo(EmotionStyle estilo, bool detectando) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    // Sin catalogo no hay tienda. La app no guarda copia local, asi que sin
    // conexion se dice claro en vez de mostrar una cuadricula vacia.
    if (_errorCatalogo != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40, color: AppTheme.mutedText),
              const SizedBox(height: 12),
              Text(
                'No se pudo cargar el catalogo.\n$_errorCatalogo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _cargando = true;
                    _errorCatalogo = null;
                  });
                  _catalogoSubscription?.cancel();
                  _escucharCatalogo();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnas = (constraints.maxWidth / 190).floor().clamp(2, 4);

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
                    child: TituloFeed(estilo: estilo, detectando: detectando),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnas,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final producto = _catalogo[index];
                      return ProductoCard(
                        key: ValueKey(producto.idProducto),
                        producto: producto,
                        destacado: false,
                        seleccionado:
                            _negociacion?.producto.idProducto ==
                            producto.idProducto,
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
    );
  }
}
