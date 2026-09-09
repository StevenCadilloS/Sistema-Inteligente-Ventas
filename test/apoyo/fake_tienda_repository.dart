import 'dart:async';

import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/data/repositories/tienda_repository.dart';

/// Implementacion en memoria de [TiendaRepository] para las pruebas.
///
/// Antes estas pruebas levantaban una base SQLite en memoria: era posible
/// porque la base era local. Con el backend compartido, hacerlo equivaldria a
/// exigir un PostgreSQL corriendo para poder ejecutar `flutter test`, y el
/// motor de decision no necesita una base para probarse — necesita que
/// alguien le responda.
///
/// El reparto de responsabilidades queda asi:
///
///   - Lo que prueba este doble: las reglas de adaptacion, la negociacion y
///     el UCB1, es decir, la logica que vive en Dart.
///   - Lo que prueban los archivos de supabase/tests/: el esquema, la
///     atomicidad de la venta, los correlativos, el batch, los KPIs y los
///     permisos, es decir, la logica que vive en SQL.
///
/// Este doble imita las mismas reglas que la base: descuenta stock al vender,
/// se niega a vender lo agotado y cuenta intentos y exitos por proceso de
/// persuasion. Si alguna de esas reglas cambia en SQL, tiene que cambiar aqui.
class FakeTiendaRepository implements TiendaRepository {
  FakeTiendaRepository({
    List<Producto> productos = const [],
    List<Estrategia> estrategias = const [],
    List<String> clientes = const [],
  }) : _productos = {for (final p in productos) p.codLoteProducto: p},
       _estrategias = [...estrategias],
       _clientes = {...clientes};

  final Map<String, Producto> _productos;
  List<Estrategia> _estrategias;
  final Set<String> _clientes;

  /// Todo lo registrado, para poder afirmar sobre ello en las pruebas.
  final List<InteraccionRegistrada> interacciones = [];
  final List<VentaRegistrada> ventas = [];

  int _secuenciaProceso = 0;
  int _secuenciaCliente = 0;

  StreamController<List<Producto>>? _controlador;

  List<Producto> get productos => _productos.values.toList();

  Producto producto(String cod) => _productos[cod]!;

  // --------------- LECTURAS ---------------

  @override
  Future<List<Producto>> catalogo() async =>
      _productos.values.where((p) => p.activo).toList();

  @override
  Stream<List<Producto>> observarCatalogo() {
    final controlador = _controlador ??=
        StreamController<List<Producto>>.broadcast();
    // La foto inicial se entrega en el siguiente turno del bucle de eventos,
    // igual que hace la implementacion real al suscribirse.
    scheduleMicrotask(() async {
      if (!controlador.isClosed) controlador.add(await catalogo());
    });
    return controlador.stream;
  }

  /// Simula lo que hace Realtime cuando el administrador toca algo.
  Future<void> emitirCambio() async {
    final controlador = _controlador;
    if (controlador != null && !controlador.isClosed) {
      controlador.add(await catalogo());
    }
  }

  /// Publica una oferta sobre un producto, como haria el administrador desde
  /// el panel, y la empuja a quien este escuchando.
  Future<void> publicarOferta(
    String codLoteProducto, {
    required int descuento,
    String nombre = 'Oferta de prueba',
  }) async {
    final actual = _productos[codLoteProducto]!;
    _productos[codLoteProducto] = Producto(
      codLoteProducto: actual.codLoteProducto,
      nombreProducto: actual.nombreProducto,
      tipoProducto: actual.tipoProducto,
      nombreTipoProducto: actual.nombreTipoProducto,
      precioUnitarioCentavos: actual.precioUnitarioCentavos,
      imagen: actual.imagen,
      totalDisponible: actual.totalDisponible,
      totalVecesMostrado: actual.totalVecesMostrado,
      totalVendidos: actual.totalVendidos,
      cierresVenta: actual.cierresVenta,
      activo: actual.activo,
      descuentoOferta: descuento,
      nombreOferta: nombre,
      codOferta: 'OF000001',
    );
    await emitirCambio();
  }

  @override
  Future<List<Estrategia>> estrategiasActivas() async {
    // Mismo calculo que la vista v_estrategia_desempeno: procesos de
    // persuasion distintos, no filas.
    return _estrategias.where((e) => e.activo).map((e) {
      final intentos = interacciones
          .where((i) => i.codEstrategia == e.codEstrategia)
          .map((i) => i.idProcesoPersuasion)
          .toSet();
      final exitos = ventas
          .where((v) => intentos.contains(v.idProcesoPersuasion))
          .map((v) => v.idProcesoPersuasion)
          .toSet();
      return Estrategia(
        codEstrategia: e.codEstrategia,
        nombreEstrategia: e.nombreEstrategia,
        activo: e.activo,
        intentos: intentos.length,
        exitos: exitos.length,
      );
    }).toList();
  }

  /// Reemplaza las estrategias disponibles (para probar el caso sin ninguna).
  void definirEstrategias(List<Estrategia> estrategias) {
    _estrategias = [...estrategias];
  }

  @override
  Future<String?> ultimoProductoMostrado(String codCliente) async {
    final propias = interacciones
        .where((i) => i.codCliente == codCliente)
        .toList();
    return propias.isEmpty ? null : propias.last.codLoteProducto;
  }

  @override
  Future<List<InteraccionHistorial>> historial(
    String codCliente, {
    int limite = 50,
  }) async {
    return interacciones
        .where((i) => i.codCliente == codCliente)
        .toList()
        .reversed
        .take(limite)
        .map(
          (i) => InteraccionHistorial(
            idProcesoPersuasion: i.idProcesoPersuasion,
            codCliente: i.codCliente,
            nivelDeInteres: i.nivelDeInteres,
            fecha: i.fecha,
            nombreGesto: i.emocion,
            nombreProducto: _productos[i.codLoteProducto]?.nombreProducto,
          ),
        )
        .toList();
  }

  @override
  Future<bool> existeCliente(String codCliente) async =>
      _clientes.contains(codCliente);

  // --------------- ESCRITURAS ---------------

  @override
  Future<String> registrarCliente({
    required String nombre,
    required String apellido,
    String? tipoCliente,
  }) async {
    if (nombre.trim().isEmpty || apellido.trim().isEmpty) {
      throw StateError('Nombre y apellido son obligatorios');
    }
    _secuenciaCliente++;
    final cod = 'C${_secuenciaCliente.toString().padLeft(7, '0')}';
    _clientes.add(cod);
    return cod;
  }

  @override
  Future<String> registrarInteraccion({
    required String codCliente,
    required String emocion,
    required String codLoteProducto,
    String? codEstrategia,
    required int nivelDeInteres,
  }) async {
    _secuenciaProceso++;
    final proceso = 'PP${_secuenciaProceso.toString().padLeft(8, '0')}';

    interacciones.add(
      InteraccionRegistrada(
        idProcesoPersuasion: proceso,
        codCliente: codCliente,
        emocion: emocion,
        codLoteProducto: codLoteProducto,
        codEstrategia: codEstrategia,
        nivelDeInteres: nivelDeInteres,
        fecha: DateTime.now(),
      ),
    );

    // Igual que fn_registrar_interaccion: sin esto, las reglas "neutral" (lo
    // mas mostrado) y "sorpresa" (lo menos mostrado) nunca cambiarian.
    final actual = _productos[codLoteProducto];
    if (actual != null) {
      _productos[codLoteProducto] = actual.copyWith(
        totalVecesMostrado: actual.totalVecesMostrado + 1,
      );
    }

    return proceso;
  }

  /// Registra una interaccion con un proceso de persuasion elegido a mano.
  ///
  /// Sirve para armar el caso en que un mismo proceso tiene varias filas con
  /// la misma estrategia (pasa de verdad: el cliente ve el producto, lo
  /// rechaza y se le insiste dentro del mismo proceso). Es justo el caso que
  /// distingue "contar procesos" de "contar filas" en el UCB1.
  void registrarInteraccionEnProceso({
    required String idProcesoPersuasion,
    required String codCliente,
    required String codLoteProducto,
    String? codEstrategia,
    String emocion = 'neutral',
    int nivelDeInteres = 50,
  }) {
    interacciones.add(
      InteraccionRegistrada(
        idProcesoPersuasion: idProcesoPersuasion,
        codCliente: codCliente,
        emocion: emocion,
        codLoteProducto: codLoteProducto,
        codEstrategia: codEstrategia,
        nivelDeInteres: nivelDeInteres,
        fecha: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> registrarVenta({
    required String idProcesoPersuasion,
    int? precioFinalCentavos,
  }) async {
    final propias = interacciones
        .where((i) => i.idProcesoPersuasion == idProcesoPersuasion)
        .toList();
    if (propias.isEmpty) {
      throw StateError('No existe el proceso $idProcesoPersuasion');
    }
    final interaccion = propias.last;

    final producto = _productos[interaccion.codLoteProducto]!;
    if (producto.totalDisponible <= 0) {
      throw SinStockException('Sin stock de ${producto.nombreProducto}');
    }

    _productos[producto.codLoteProducto] = producto.copyWith(
      totalDisponible: producto.totalDisponible - 1,
    );

    ventas.add(
      VentaRegistrada(
        idProcesoPersuasion: idProcesoPersuasion,
        codLoteProducto: producto.codLoteProducto,
        codEstrategia: interaccion.codEstrategia,
        precioUnitarioCentavos:
            precioFinalCentavos ?? producto.precioUnitarioCentavos,
      ),
    );
  }

  @override
  Future<void> ejecutarCierreDiario() async {}

  Future<void> cerrar() async {
    await _controlador?.close();
    _controlador = null;
  }
}

class InteraccionRegistrada {
  const InteraccionRegistrada({
    required this.idProcesoPersuasion,
    required this.codCliente,
    required this.emocion,
    required this.codLoteProducto,
    required this.codEstrategia,
    required this.nivelDeInteres,
    required this.fecha,
  });

  final String idProcesoPersuasion;
  final String codCliente;
  final String emocion;
  final String codLoteProducto;
  final String? codEstrategia;
  final int nivelDeInteres;
  final DateTime fecha;
}

class VentaRegistrada {
  const VentaRegistrada({
    required this.idProcesoPersuasion,
    required this.codLoteProducto,
    required this.codEstrategia,
    required this.precioUnitarioCentavos,
  });

  final String idProcesoPersuasion;
  final String codLoteProducto;
  final String? codEstrategia;
  final int precioUnitarioCentavos;
}
