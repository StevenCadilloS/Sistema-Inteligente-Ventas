import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/modelos.dart';
import 'tienda_repository.dart';

/// Implementacion de [TiendaRepository] contra PostgreSQL (Supabase).
///
/// Lecturas por PostgREST sobre las vistas `v_catalogo`, `v_estrategia_desempeno`
/// e `interacciones`; escrituras exclusivamente por RPC contra las funciones
/// de supabase/migrations/0002_funciones.sql. La app no tiene permiso de
/// INSERT ni de UPDATE sobre ninguna tabla: la clave anonima esta dentro del
/// APK y quien la extraiga no debe poder tocar precios ni stock.
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
        .eq('activo', true);
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

  /// El evento de Realtime dice que cambio una fila de `productos` u `ofertas`,
  /// pero lo que la tienda necesita es el catalogo ya compuesto (producto +
  /// oferta vigente + precio resultante), y eso vive en una vista. Postgres
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
  Future<List<Estrategia>> estrategiasActivas() async {
    final filas = await _cliente
        .from('v_estrategia_desempeno')
        .select()
        .eq('activo', true);
    return filas.map(Estrategia.desdeFila).toList();
  }

  @override
  Future<String?> ultimoProductoMostrado(String codCliente) async {
    final fila = await _cliente
        .from('interacciones')
        .select('cod_lote_producto')
        .eq('cod_cliente', codCliente)
        .not('cod_lote_producto', 'is', null)
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();
    return fila?['cod_lote_producto'] as String?;
  }

  @override
  Future<List<InteraccionHistorial>> historial(
    String codCliente, {
    int limite = 50,
  }) async {
    // Los joins van embebidos en el select: PostgREST los resuelve por las
    // claves foraneas declaradas en el esquema. Es el equivalente del join
    // manual que hacia la pantalla contra drift, en un solo viaje.
    final filas = await _cliente
        .from('interacciones')
        .select(
          'id_proceso_persuasion, cod_cliente, nivel_de_interes, timestamp, '
          'gestos(nombre_gesto), estrategias(nombre_estrategia), '
          'productos(nombre_producto)',
        )
        .eq('cod_cliente', codCliente)
        .order('timestamp', ascending: false)
        .limit(limite);
    return filas.map(InteraccionHistorial.desdeFila).toList();
  }

  @override
  Future<bool> existeCliente(String codCliente) async {
    final fila = await _cliente
        .from('clientes')
        .select('cod_cliente')
        .eq('cod_cliente', codCliente)
        .maybeSingle();
    return fila != null;
  }

  // --------------- ESCRITURAS ---------------

  @override
  Future<String> registrarCliente({
    required String nombre,
    required String apellido,
    String? tipoCliente,
  }) async {
    final codCliente = await _cliente.rpc<String>(
      'fn_registrar_cliente',
      params: {
        'p_nombre': nombre,
        'p_apellido': apellido,
        'p_tipo_cliente': tipoCliente,
      },
    );
    return codCliente;
  }

  @override
  Future<String> registrarInteraccion({
    required String codCliente,
    required String emocion,
    required String codLoteProducto,
    String? codEstrategia,
    required int nivelDeInteres,
  }) async {
    final proceso = await _cliente.rpc<String>(
      'fn_registrar_interaccion',
      params: {
        'p_cod_cliente': codCliente,
        'p_emocion': emocion,
        'p_cod_lote_producto': codLoteProducto,
        'p_cod_estrategia': codEstrategia,
        'p_nivel_de_interes': nivelDeInteres,
      },
    );
    return proceso;
  }

  @override
  Future<void> registrarVenta({
    required String idProcesoPersuasion,
    int? precioFinalCentavos,
  }) async {
    try {
      await _cliente.rpc<Object?>(
        'fn_registrar_venta',
        params: {
          'p_id_proceso_persuasion': idProcesoPersuasion,
          'p_precio_final_centavos': precioFinalCentavos,
        },
      );
    } on PostgrestException catch (e) {
      // El `hint` lo pone la funcion SQL a proposito, para poder distinguir
      // "se agoto" de un fallo real sin leer el texto del mensaje, que cambia
      // con el idioma del servidor.
      if (e.hint == 'sin_stock') {
        throw SinStockException(e.message);
      }
      rethrow;
    }
  }

  @override
  Future<void> ejecutarCierreDiario() =>
      _cliente.rpc<Object?>('fn_cierre_diario');

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
