import 'dart:async';

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

  // --------------- LECTURAS ---------------

  @override
  Future<List<Producto>> catalogo() async {
    final filas = await _cliente
        .from('v_catalogo')
        .select()
        .eq('activo', true)
        .gt('stock', 0);
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
              callback: (_) => _emitirCatalogo(controlador),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ofertas',
              callback: (_) => _emitirCatalogo(controlador),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ofertas_productos',
              callback: (_) => _emitirCatalogo(controlador),
            )
            .subscribe();
      },
      onCancel: () async {
        final canal = _canal;
        _canal = null;
        if (canal != null) await _cliente.removeChannel(canal);
      },
    );
    _controlador = controlador;
    return controlador.stream;
  }

  /// El evento de Realtime dice que cambio una fila, pero lo que la tienda
  /// necesita es el catalogo ya compuesto, y eso vive en una vista. Postgres
  /// solo replica cambios de tablas fisicas, asi que el evento se usa como
  /// senal para releer, no como dato.
  Future<void> _emitirCatalogo(StreamController<List<Producto>> destino) async {
    if (destino.isClosed) return;
    try {
      destino.add(await catalogo());
    } catch (e, s) {
      if (!destino.isClosed) destino.addError(e, s);
    }
  }

  @override
  Future<List<EscalonOferta>> ofertasDe({
    required int idProducto,
    required int idCliente,
  }) async {
    // fn_ofertas_de ya aplica las tres condiciones (producto, vigencia y
    // limite diario del cliente) en el servidor. La app no las reimplementa:
    // duplicar una regla es como se termina con dos versiones que no
    // coinciden.
    final filas = await _cliente.rpc<List<dynamic>>(
      'fn_ofertas_de',
      params: {'p_id_producto': idProducto, 'p_id_cliente': idCliente},
    );
    return filas
        .cast<Map<String, dynamic>>()
        .map(EscalonOferta.desdeFila)
        .toList();
  }

  @override
  Future<bool> puedeUsarOferta(int idCliente) async {
    final resultado = await _cliente.rpc<bool>(
      'fn_puede_usar_oferta',
      params: {'p_id_cliente': idCliente},
    );
    return resultado;
  }

  @override
  Future<List<CompraHistorial>> historial(
    int idCliente, {
    int limite = 50,
  }) async {
    // `venta` no es de lectura publica: el historial sale por una funcion que
    // devuelve solo las compras del cliente que se pide.
    final filas = await _cliente.rpc<List<dynamic>>(
      'fn_historial',
      params: {'p_id_cliente': idCliente, 'p_limite': limite},
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
    String? correo,
  }) async {
    final id = await _cliente.rpc<int>(
      'fn_registrar_cliente',
      params: {
        'p_nombre': nombre,
        'p_paterno': paterno,
        'p_materno': materno,
        'p_telefono': telefono,
        'p_correo': correo,
      },
    );
    return id;
  }

  @override
  Future<int> registrarVenta({
    required int idCliente,
    required int idProducto,
    int cantidad = 1,
    int? idOferta,
  }) async {
    try {
      return await _cliente.rpc<int>(
        'fn_registrar_venta',
        params: {
          'p_id_cliente': idCliente,
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
        default:
          rethrow;
      }
    }
  }

  /// Cierra el canal de Realtime. La app lo llama al salir de la tienda; sin
  /// esto queda un websocket abierto consumiendo bateria en segundo plano.
  Future<void> cerrar() async {
    final canal = _canal;
    _canal = null;
    if (canal != null) await _cliente.removeChannel(canal);
    await _controlador?.close();
    _controlador = null;
  }
}
