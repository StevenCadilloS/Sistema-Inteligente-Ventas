import 'dart:async';

import 'package:flutter/material.dart';

import '../data/modelos/modelos.dart';
import '../data/repositories/tienda_repository.dart';
import '../decision/negociacion.dart';
import '../services/emotion_channel.dart';
import '../theme/app_theme.dart';
import 'widgets/banner_esperando.dart';
import 'widgets/carrito_hoja.dart';
import 'widgets/chip_emocion.dart';
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
    required this.onCerrarSesion,
    required this.emotionChannel,
    required this.tienda,
    this.clasificador = const ClasificadorRespuesta(),
    this.ventanaObservacion = const Duration(seconds: 8),
  });

  /// Que hacer al pulsar "cerrar sesion".
  ///
  /// Es un callback y no el SesionService entero porque ese servicio envuelve
  /// el SDK de Supabase y no se puede construir sin un cliente vivo: exigirlo
  /// aqui dejaba la pantalla imposible de montar en una prueba, que es justo
  /// donde aparecieron los ultimos fallos (el boton de rechazar, la ventana
  /// de observacion). La pantalla solo necesita saber a quien avisar.
  final Future<void> Function() onCerrarSesion;

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

class _TiendaScreenState extends State<TiendaScreen> with WidgetsBindingObserver {
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

  /// El carrito del cliente: intenciones, no ventas. Nada de esta lista ha
  /// pasado por fn_confirmar_carrito; se cobra al confirmar, y solo si el
  /// servidor encuentra el carrito tal como la pantalla lo congo.
  final List<LineaCarrito> _carrito = [];

  /// La confirmacion esta en vuelo: cotizar, avisar si algo cambio y
  /// cobrar. Mientras dura, el carrito se congela.
  bool _confirmando = false;

  /// La hoja del carrito esta sobre la pantalla. Sirve para no apilar dos
  /// hojas si el cliente toca el icono mientras la de abajo sigue, y para
  /// saber si tocar pop cierra la hoja o una parte de la tienda.
  bool _carritoAbierto = false;

  /// Hay sesion pero falta la ficha de cliente. Se puede mirar el catalogo,
  /// no comprar.
  bool _sinFicha = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _escucharCatalogo();
    _comprobarFicha();
  }

  /// Android/iOS suelen suspender el websocket de Realtime cuando la app pasa
  /// a segundo plano. Al volver, el socket puede reconectarse solo, pero
  /// cualquier evento ocurrido mientras estuvo desconectado se pierde — no
  /// hay replay. Sin esto, el catalogo se queda congelado hasta cerrar sesion
  /// y volver a entrar, que es lo que recrea la pantalla entera.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refrescarCatalogo();
  }

  /// Relectura directa del catalogo, al margen de Realtime. Sirve de red de
  /// seguridad: si el stream se perdio un cambio, esto lo corrige sin
  /// esperar al siguiente evento.
  Future<void> _refrescarCatalogo() async {
    try {
      final productos = await widget.tienda.catalogo();
      if (!mounted) return;
      setState(() => _catalogo = productos);
    } catch (_) {
      // Si falla, el stream de Realtime sigue intentando por su cuenta; no
      // hay que convertir esto en un error visible para el cliente.
    }
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

  /// Verdadero mientras la pantalla se esta destruyendo.
  ///
  /// `mounted` NO sirve para esto: sigue siendo true durante todo dispose(),
  /// hasta que super.dispose() termina. Llamar setState ahi lanza
  /// "_lifecycleState != _ElementLifecycle.defunct" — que es lo que pasaba al
  /// salir de la tienda con una negociacion abierta.
  bool _destruyendo = false;

  @override
  void dispose() {
    _destruyendo = true;
    WidgetsBinding.instance.removeObserver(this);
    _catalogoSubscription?.cancel();
    _terminarInteraccion(); // apaga la camara y cierra el popup
    super.dispose();
  }

  /// setState solo si la pantalla sigue viva y no se esta destruyendo.
  void _actualizar(VoidCallback cambio) {
    if (_destruyendo || !mounted) {
      cambio();
      return;
    }
    setState(cambio);
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

    if (producto.stock <= 0) {
      // Defensa por si el toque llego justo cuando Realtime todavia no habia
      // pintado el agotado: la tarjeta ya deberia tener el onTap apagado.
      _avisar('${producto.nombre} esta agotado.');
      return;
    }

    if (_sinFicha) {
      _avisar('Completa tu registro para poder comprar.');
      return;
    }

    if (_enCarrito(producto)) {
      // Si ya esta en el carrito, renegociar pondria dos precios distintos
      // para el mismo producto y el ajuste pasa por las cantidades: la
      // negociacion se queda de lado y se abre el carrito.
      _avisar('${producto.nombre} ya esta en tu carrito; ajusta el numero '
          'de unidades desde ahi.');
      _abrirCarrito();
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
      onAceptar: () => _agregarAlCarrito(negociacion),
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

  /// El cliente dijo "Lo quiero": la negociacion termino y el precio que
  /// estaba en pantalla queda congelado en la linea del carrito.
  ///
  /// NO registra la venta: eso pasa al confirmar el carrito, y solo si el
  /// servidor determina el mismo precio que la pantalla congo. La camara se
  /// apaga aqui: la persuasion ya tuvo su final, y seguir mirendo la cara
  /// mientras el producto espera en el carrito no cambia nada.
  void _agregarAlCarrito(Negociacion negociacion) {
    final producto = negociacion.producto;
    final unidad = LineaCarrito(
      producto: producto,
      cantidad: 1,
      idOferta: negociacion.idOfertaActual,
      acordadoCentavos: negociacion.precioActualCentavos,
    );

    _actualizar(() {
      // Dos lineas iguales no se acumulan: un producto tiene UN lugar en el
      // carrito, y el ajuste de unidades es +/- de la linea. El precio
      // congelado no se reescribe: lo visto en pantalla quedo en pantalla.
      final en = _carrito.indexWhere(
        (l) => l.producto.idProducto == producto.idProducto,
      );
      if (en >= 0) {
        final previa = _carrito[en];
        _carrito[en] = previa.conCantidad(previa.cantidad + 1);
      } else {
        _carrito.add(unidad);
      }
    });

    _terminarInteraccion();
    _avisar(
      'Agregaste ${producto.nombre} a tu carrito (${soles(unidad.acordadoCentavos)} c/u).',
    );
  }

  /// Termina la interaccion: apaga la camara, cierra el popup y olvida la
  /// negociacion. Se llama tanto al agregar como al abandonar.
  void _terminarInteraccion() {
    _apagarCamara();
    _overlay?.remove();
    _overlay = null;
    _actualizar(() => _negociacion = null);
  }

  void _apagarCamara() {
    _ventana?.cancel();
    _ventana = null;
    _emociones?.cancel();
    _emociones = null;
    _lecturas.clear();
    _actualizar(() {
      _emocionDetectada = null;
      _confianza = 0;
    });
  }

  // --------------- AYUDAS ---------------

  bool _enCarrito(Producto producto) =>
      _carrito.any((l) => l.producto.idProducto == producto.idProducto);

  /// Unidades totales en el carrito: es lo que cuenta el badge del AppBar.
  int get _unidadesEnCarrito =>
      _carrito.fold(0, (n, l) => n + l.cantidad);

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
    await widget.onCerrarSesion();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  void _abrirCarrito() {
    // Sin esto, tocar el icono con la hoja ya abierta apila otra hoja igual
    // encima.
    if (_carritoAbierto) return;

    _carritoAbierto = true;
    // La Future de la hoja se resuelve cuando se cierra; whenComplete suelta
    // la marca por corra la puerta con que toco salir: swipe, boton o pop.
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible: !_confirmando,
        enableDrag: !_confirmando,
        builder: (contextHoja) {
          // La hoja no se reconstruye sola cuando cambia el estado de la
          // pantalla: StatefulBuilder la pinta entre setState externo e
          // interno, con las mutaciones de ambas partes.
          return StatefulBuilder(
            builder: (contextHoja, setHoja) {
              void refrescarHoja() {
                if (mounted) setState(() {});
                setHoja(() {});
              }

              return CarritoHoja(
                lineas: List.of(_carrito),
                confirmando: _confirmando,
                onCantidad: (linea, nuevaCantidad) {
                  if (nuevaCantidad < 1) {
                    _carrito.remove(linea);
                  } else {
                    final i = _carrito.indexOf(linea);
                    if (i >= 0) _carrito[i] = linea.conCantidad(nuevaCantidad);
                  }
                  refrescarHoja();
                },
                onEliminar: (linea) {
                  _carrito.remove(linea);
                  refrescarHoja();
                },
                onVaciar: () {
                  _carrito.clear();
                  refrescarHoja();
                },
                onConfirmar: () => unawaited(_confirmarCompra(refrescarHoja)),
                onSeguirComprando: () => Navigator.pop(contextHoja),
              );
            },
          );
        },
      ).whenComplete(() => _carritoAbierto = false),
    );
  }

  // --------------- CONFIRMAR LA COMPRA ---------------
  //
  // La cadena es: cotizar (que dice el catalogo HOY por cada linea) ->
  // avisar si algo dejo de cuadrar con lo congelado en pantalla (la decision
  // tomada: se avisa y el cliente decide) -> fn_confirmar_carrito con las
  // lineas en su estado final. El servidor vuelve a verificar todo; si
  // mientras tanto algo cambio de nuevo, el rechazo regresa aqui.

  Future<void> _confirmarCompra(VoidCallback? refrescarHoja) async {
    if (_confirmando || _carrito.isEmpty) return;

    void termino() {
      _actualizar(() => _confirmando = false);
      refrescarHoja?.call();
    }

    try {
      // Re-run del cotizar/avisar: mientras el usuario lee el aviso y
      // contesta, el catalogo puede volver a moverse. Cada reincidencia
      // vuelve a empezar; en corrida normal esto no gira dos veces.
      while (true) {
        final cambios = await _cotizarConAviso();
        if (cambios == null) return; // el cliente cancelo

        try {
          final total = _carrito.fold<int>(0, (n, l) => n + l.totalCentavos);
          final items = _carrito.fold<int>(0, (n, l) => n + l.cantidad);
          await widget.tienda.confirmarCarrito(lineas: List.of(_carrito));

          if (!mounted) return;
          _carrito.clear();
          termino();
          if (_carritoAbierto && mounted) Navigator.pop(context);
          _avisar(
            'Compraste $items ${items == 1 ? 'producto' : 'productos'} '
            'por ${soles(total)}',
          );
          return;
        } on PrecioCambioException {
          // El catalogo se movio entre el aviso y el cobro. La siguiente
          // vuelta vuelve a cotizar y reconstruye el aviso con lo nuevo.
          if (!mounted) return;
          _avisar('El catalogo cambio otra vez; se reconstruye el aviso');
        }
      }
    } on SinSesionException {
      if (!mounted) return;
      termino();
      Navigator.pop(context);
      _volverAlLogin();
      return;
    } on SinStockException catch (e) {
      if (!mounted) return;
      termino();
      _avisar('No se pudo confirmar: $e');
      return;
    } on LimiteOfertasException catch (e) {
      if (!mounted) return;
      termino();
      // Aviso ya conocido a la altura del confirmar: la cotizacion lo habria
      // marcado... si un vecino gasto el cupo en el minimo intermedio.
      _avisar('$e. Puedes confirmar a precio normal quitando las ofertas.');
      return;
    } catch (e) {
      if (!mounted) return;
      termino();
      _avisar('No se pudo confirmar la compra: $e');
      return;
    }
  }

  /// Cotiza y, si el catalogo no cuadra con lo congelado en pantalla, muestra
  /// el aviso y resuelve la respuesta del cliente.
  ///
  /// Devuelve null si la confirmacion se cancela; si toca continuar, el
  /// estado de [_carrito] queda ya ajustado a lo cotizado.
  Future<bool?> _cotizarConAviso() async {
    try {
      final cotizaciones = await widget.tienda.cotizarCarrito(
        lineas: List.of(_carrito),
      );

      final cambiadas = <_CambioAviso>[];
      for (var i = 0; i < _carrito.length; i++) {
        final linea = _carrito[i];
        // El servidor devuelve las cotizaciones en el orden del pedido. Si
        // la entrega no cubre la linea, no hay contra que compararla.
        if (i >= cotizaciones.length) break;
        final cot = cotizaciones[i];
        if (cot.respeta(linea)) continue;

        final motivo = !cot.stockSuficiente
            ? 'quedo sin stock suficiente'
            : !cot.ofertaAplicada
            ? 'la oferta ya no corre: sale a ${soles(cot.precioUnitarioCentavos)}'
            : 'cambio de ${soles(linea.acordadoCentavos)} a '
                '${soles(cot.precioUnitarioCentavos)}';
        cambiadas.add(
          _CambioAviso(
            linea: linea,
            cotizacion: cot,
            texto: '${linea.producto.nombre} $motivo',
          ),
        );
      }

      if (cambiadas.isEmpty) return true;
      if (!mounted) return null;

      final respuesta = await showDialog<_QueHacer>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DialogoCambios(cambios: cambiadas),
      );
      if (respuesta == null || !mounted) return null;

      switch (respuesta) {
        case _QueHacer.seguirConLosNuevos:
          _aplicarCotizaciones(cotizaciones);
          return true;
        case _QueHacer.quitarLosCambiados:
          for (final c in cambiadas) {
            _carrito.remove(c.linea);
          }
          return _carrito.isNotEmpty ? true : null;
      }
    } on SinSesionException {
      rethrow;
    } catch (e) {
      if (!mounted) return null;
      _avisar('No se pudo cotizar el carrito: $e');
      return null;
    }
  }

  /// Escribe en el carrito lo que el servidor determino por linea. Se usa
  /// solo cuando el cliente acepto los nuevos precios: a partir de aqui las
  /// lineas coinciden con lo que se cobra.
  void _aplicarCotizaciones(List<CotizacionLinea> cotizaciones) {
    for (var i = 0; i < _carrito.length && i < cotizaciones.length; i++) {
      final linea = _carrito[i];
      final cot = cotizaciones[i];
      _carrito[i] = LineaCarrito(
        producto: linea.producto,
        cantidad: linea.cantidad,
        idOferta: cot.ofertaAplicada ? cot.idOferta : null,
        acordadoCentavos: cot.precioUnitarioCentavos,
      );
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
              if (_unidadesEnCarrito > 0)
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
                      '$_unidadesEnCarrito',
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
                        comprado: _enCarrito(producto),
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

// --------------- EL AVISO DE PRECIOS QUE CAMBIARON ---------------

/// Que hacer con las lineas que ya no salian como la pantalla las congelo.
enum _QueHacer { seguirConLosNuevos, quitarLosCambiados }

/// Una linea cuyo precio o stock ya no coincide con lo que la pantalla congeló
/// durante la negociacion. [texto] es la frase que se le muestra al cliente.
class _CambioAviso {
  const _CambioAviso({
    required this.linea,
    required this.cotizacion,
    required this.texto,
  });

  final LineaCarrito linea;
  final CotizacionLinea cotizacion;
  final String texto;
}

/// El dialogo de la decision tomada: avisar y dejar que el cliente decida.
///
/// Con que UN centavo no cuadre sale este dialogo: seguir aceptando los
/// precios nuevos (el carrito queda exactamente como se cobrara), quitar las
/// lineas cambiadas y confirmar el resto, o no confirmar nada.
class _DialogoCambios extends StatelessWidget {
  const _DialogoCambios({required this.cambios});

  final List<_CambioAviso> cambios;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Los precios ya no son los mismos'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'El catalogo cambio mientras decidias. Ahora mismo:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          for (final cambio in cambios) ...[
            Text(
              cambio.texto,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, _QueHacer.quitarLosCambiados),
          child: const Text('Quitar del carrito'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _QueHacer.seguirConLosNuevos),
          child: const Text('Continuar con los nuevos'),
        ),
      ],
    );
  }
}
