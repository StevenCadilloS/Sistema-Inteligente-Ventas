import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/modelos.dart';
import 'tienda_repository.dart';

/// Implementacion de [TiendaRepository] contra PostgreSQL (Supabase).
///
/// Lecturas por PostgREST sobre la vista `v_catalogo`; escrituras y consultas
/// de ofertas exclusivamente por RPC contra las funciones de
/// supabase/migrations/0002_funciones.sql.
///
/// La app no tiene permiso de INSERT ni de UPDATE sobre ninguna tabla, y
/// tampoco de SELECT sobre `clientes`, `venta` ni `detalle_venta`: la clave
/// publica esta dentro del APK y quien la extraiga no debe poder tocar
/// precios, stock ni leer las compras de otras personas.
class SupabaseTiendaRepository implements TiendaRepository {
  SupabaseTiendaRepository(this._cliente);

  final SupabaseClient _cliente;

  /// Un solo canal para todo el catalogo. Se abre con el primer suscriptor y
  /// se cierra con el ultimo.
  RealtimeChannel? _canal;
  StreamController<List<Producto>>? _controlador;

  /// Agrupa la rafaga de eventos que produce una edicion en el panel. Ver
  /// [_programarRelectura].
  Timer? _reintento;

  /// Evita que dos relecturas solapadas pinten resultados en desorden.
  bool _leyendo = false;
  bool _relecturaPendiente = false;

  // --------------- LECTURAS ---------------

  @override
  Future<List<Producto>> catalogo() async {
    // Sin el filtro de stock: los agotados se quedan en el feed, marcados
    // como tal, en vez de desaparecer. Que un producto se esfume de golpe
    // confunde mas que verlo con la franja de "Agotado".
    final filas = await _cliente.from('v_catalogo').select().eq('activo', true);
    return filas.map(Producto.desdeFila).toList();
  }

  @override
  Stream<List<Producto>> observarCatalogo() {
    final existente = _controlador;
    if (existente != null && !existente.isClosed) return existente.stream;

    late final StreamController<List<Producto>> controlador;
    controlador = StreamController<List<Producto>>.broadcast(
      onListen: () {
        // Foto inicial: sin esto la pantalla se queda vacia hasta que el
        // administrador toque algo, que puede no pasar nunca.
        _emitirCatalogo(controlador);
        _canal = _cliente
            .channel('catalogo_publico')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'productos',
              callback: (_) => _programarRelectura(controlador),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ofertas',
              callback: (_) => _programarRelectura(controlador),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ofertas_productos',
              callback: (_) => _programarRelectura(controlador),
            )
            .subscribe((status, error) {
              // Sin esto, un fallo de suscripcion (canal caido, token
              // vencido, limite del proyecto) queda mudo: el stream nunca
              // vuelve a emitir y nada en los logs explica por que.
              if (status == RealtimeSubscribeStatus.channelError ||
                  status == RealtimeSubscribeStatus.timedOut) {
                debugPrint('Realtime catalogo_publico: $status ($error)');
              }
            });
      },
      onCancel: () async {
        _reintento?.cancel();
        _reintento = null;
        final canal = _canal;
        _canal = null;
        if (canal != null) await _cliente.removeChannel(canal);
      },
    );
    _controlador = controlador;
    return controlador.stream;
  }

  /// Agrupa los eventos de Realtime en una sola relectura.
  ///
  /// Una edicion en el panel casi nunca es un evento: publicar una oferta toca
  /// `ofertas` y `ofertas_productos`, y reponer varios productos dispara uno
  /// por fila. Sin agrupar, cada uno lanzaba su propio viaje de red para
  /// releer el catalogo entero — con 10 productos editados, 10 consultas para
  /// pintar el mismo resultado.
  ///
  /// 300 ms es suficiente para juntar una rafaga y lo bastante corto para que
  /// el cambio siga pareciendo instantaneo.
  void _programarRelectura(StreamController<List<Producto>> destino) {
    _reintento?.cancel();
    _reintento = Timer(
      const Duration(milliseconds: 300),
      () => _emitirCatalogo(destino),
    );
  }

  /// El evento de Realtime dice que cambio una fila, pero lo que la tienda
  /// necesita es el catalogo ya compuesto, y eso vive en una vista. Postgres
  /// solo replica cambios de tablas fisicas, asi que el evento se usa como
  /// senal para releer, no como dato.
  ///
  /// Dos relecturas no se solapan: si llega un evento mientras una esta en
  /// vuelo, se marca una pendiente y se lanza al terminar. Sin esto, dos
  /// consultas simultaneas podian resolverse en orden inverso y dejar el feed
  /// mostrando datos mas viejos que los que ya habia pintado.
  Future<void> _emitirCatalogo(StreamController<List<Producto>> destino) async {
    if (destino.isClosed) return;

    if (_leyendo) {
      _relecturaPendiente = true;
      return;
    }
    _leyendo = true;

    try {
      final productos = await catalogo();
      if (!destino.isClosed) destino.add(productos);
    } catch (e, s) {
      if (!destino.isClosed) destino.addError(e, s);
    } finally {
      _leyendo = false;
      if (_relecturaPendiente) {
        _relecturaPendiente = false;
        unawaited(_emitirCatalogo(destino));
      }
    }
  }

  @override
  Future<List<EscalonOferta>> ofertasDe(int idProducto) async {
    // fn_ofertas_de aplica las tres condiciones (producto, vigencia y limite
    // diario) en el servidor, y saca el cliente del token. La app no las
    // reimplementa: duplicar una regla es como se termina con dos versiones
    // que no coinciden.
    final filas = await _cliente.rpc<List<dynamic>>(
      'fn_ofertas_de',
      params: {'p_id_producto': idProducto},
    );
    return filas
        .cast<Map<String, dynamic>>()
        .map(EscalonOferta.desdeFila)
        .toList();
  }

  @override
  Future<bool> puedeUsarOferta() async =>
      await _cliente.rpc<bool>('fn_puede_usar_oferta');

  @override
  Future<int?> clienteActual() async =>
      await _cliente.rpc<int?>('fn_cliente_actual');

  @override
  Future<List<CompraHistorial>> historial({int limite = 50}) async {
    // `venta` no es de lectura publica, y el historial no recibe a quien
    // consultar: devuelve las compras de quien trae el token. Asi nadie puede
    // pedir el historial de otra persona.
    final filas = await _cliente.rpc<List<dynamic>>(
      'fn_historial',
      params: {'p_limite': limite},
    );
    return filas
        .cast<Map<String, dynamic>>()
        .map(CompraHistorial.desdeFila)
        .toList();
  }

  // --------------- ESCRITURAS ---------------

  @override
  Future<int> registrarCliente({
    required String nombre,
    String? paterno,
    String? materno,
    String? telefono,
  }) async {
    try {
      // El correo no va: lo toma el servidor del token ya verificado.
      return await _cliente.rpc<int>(
        'fn_registrar_cliente',
        params: {
          'p_nombre': nombre,
          'p_paterno': paterno,
          'p_materno': materno,
          'p_telefono': telefono,
        },
      );
    } on PostgrestException catch (e) {
      if (e.hint == 'sin_sesion') throw const SinSesionException();
      rethrow;
    }
  }

  @override
  Future<int> registrarVenta({
    required int idProducto,
    int cantidad = 1,
    int? idOferta,
  }) async {
    try {
      // Ni el cliente ni el precio viajan: el primero sale del token, el
      // segundo lo recalcula el servidor.
      return await _cliente.rpc<int>(
        'fn_registrar_venta',
        params: {
          'p_id_producto': idProducto,
          'p_cantidad': cantidad,
          'p_id_oferta': idOferta,
        },
      );
    } on PostgrestException catch (e) {
      // El `hint` lo ponen las funciones SQL a proposito, para poder
      // distinguir un caso de otro sin leer el texto del mensaje, que cambia
      // con el idioma del servidor.
      switch (e.hint) {
        case 'sin_stock':
          throw SinStockException(e.message);
        case 'limite_diario':
          throw LimiteOfertasException(e.message);
        case 'sin_sesion':
          throw const SinSesionException();
        default:
          rethrow;
      }
    }
  }

  /// Cierra el canal de Realtime. La app lo llama al salir de la tienda; sin
  /// esto queda un websocket abierto consumiendo bateria en segundo plano.
  Future<void> cerrar() async {
    _reintento?.cancel();
    _reintento = null;
    final canal = _canal;
    _canal = null;
    if (canal != null) await _cliente.removeChannel(canal);
    await _controlador?.close();
    _controlador = null;
  }
}
