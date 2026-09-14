import 'dart:async';

import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/data/repositories/tienda_repository.dart';

/// Doble en memoria de [TiendaRepository].
///
/// Replica lo que hacen las funciones del servidor, incluidas las reglas que
/// importan: el limite de UNA oferta por dia que solo consumen las compras
/// con oferta (0013), el descuento de stock y el calculo del precio de cada
/// escalon. Si este doble fuera mas permisivo que el servidor, las pruebas
/// pasarian y la app fallaria contra la base real.
///
/// Lo que NO replica es la seguridad: aqui no hay RLS ni permisos. Eso se
/// prueba en SQL (supabase/tests/04_seguridad.sql), que es donde vive.
class FakeTiendaRepository implements TiendaRepository {
  FakeTiendaRepository({
    List<Producto> productos = const [],
    Map<int, List<EscalonOferta>> escaleras = const {},
  }) : _productos = [...productos],
       _escaleras = {...escaleras};

  final List<Producto> _productos;

  /// id de producto -> su escalera de ofertas, en orden.
  final Map<int, List<EscalonOferta>> _escaleras;

  /// Ventas, fila por linea de detalle. Las lineas de una confirmacion del
  /// carrito comparten idVenta: es la misma forma que deja
  /// fn_confirmar_carrito en la base, y de ahi sale que el historial devuelve
  /// una fila por linea y el limite diario cuente ventas distintas.
  final List<VentaFake> ventas = [];
  final Map<int, String> clientes = {};

  /// Quien esta identificado. null = sin sesion, que es como arranca: en el
  /// servidor esto sale del token, aqui se fija a mano con [iniciarSesion].
  int? _sesion;

  int _siguienteCliente = 1;
  int _siguienteVenta = 1;

  StreamController<List<Producto>>? _controlador;

  /// Reloj de la prueba. Se puede mover para comprobar que el limite diario
  /// se renueva: `repo.ahora = () => DateTime(2026, 9, 12);`
  DateTime Function() ahora = DateTime.now;

  Producto producto(int id) =>
      _productos.firstWhere((p) => p.idProducto == id);

  /// El administrador toca un precio desde el panel, mientras el cliente
  /// revisa su carrito.
  void cambiarPrecio(int idProducto, int centavos) {
    final i = _productos.indexWhere((p) => p.idProducto == idProducto);
    _productos[i] = _productos[i].copyWith(precioCentavos: centavos);
  }

  /// Simula el token: a partir de aqui, el repositorio responde como si
  /// llamara este cliente. Equivale a fn_simular_sesion en las pruebas SQL.
  void iniciarSesion(int? idCliente) => _sesion = idCliente;

  int _exigirSesion() {
    final id = _sesion;
    if (id == null) throw const SinSesionException();
    return id;
  }

  // --------------- LECTURAS ---------------

  @override
  Future<List<Producto>> catalogo() async =>
      _productos.where((p) => p.activo).toList();

  @override
  Stream<List<Producto>> observarCatalogo() {
    final existente = _controlador;
    if (existente != null && !existente.isClosed) return existente.stream;

    late final StreamController<List<Producto>> c;
    c = StreamController<List<Producto>>.broadcast(
      onListen: () async => c.add(await catalogo()),
    );
    _controlador = c;
    return c.stream;
  }

  @override
  Future<List<EscalonOferta>> ofertasDe(int idProducto) async {
    _exigirSesion();
    // Igual que fn_ofertas_de: si el cliente gasto su cupo, la escalera viene
    // vacia. La app no tiene que saber por que.
    if (!await puedeUsarOferta()) return const [];

    final escalera = _escaleras[idProducto] ?? const <EscalonOferta>[];
    return [...escalera]..sort((a, b) => a.orden.compareTo(b.orden));
  }

  @override
  Future<bool> puedeUsarOferta() async {
    final id = _sesion;
    return id != null && _comprasDeHoy(id) < 1;
  }

  @override
  Future<int?> clienteActual() async => _sesion;

  /// Ventas con oferta de hoy del cliente: tantas como idVenta con al menos
  /// una linea con oferta, que es como cuenta fn_compras_del_dia desde 0013.
  /// Las compras a precio normal no consumen el cupo.
  int _comprasDeHoy(int idCliente) {
    final hoy = ahora();
    return ventas
        .where(
          (v) =>
              v.idCliente == idCliente &&
              v.nombreOferta != null &&
              v.fecha.year == hoy.year &&
              v.fecha.month == hoy.month &&
              v.fecha.day == hoy.day,
        )
        .map((v) => v.idVenta)
        .toSet()
        .length;
  }

  @override
  Future<List<VentaResumen>> historial({int limite = 50}) async {
    final idCliente = _exigirSesion();
    // Una fila por VENTA: las lineas de una confirmacion comparten idVenta.
    final porVenta = <int, List<VentaFake>>{};
    for (final v in ventas.where((v) => v.idCliente == idCliente)) {
      porVenta.putIfAbsent(v.idVenta, () => []).add(v);
    }
    final ordenadas = porVenta.entries.toList()
      ..sort((a, b) => b.value.first.fecha.compareTo(a.value.first.fecha));
    return ordenadas.take(limite).map((entrada) {
      final filas = entrada.value;
      return VentaResumen(
        idVenta: entrada.key,
        fecha: filas.first.fecha,
        lineas: filas.length,
        unidades: filas.fold(0, (s, v) => s + v.cantidad),
        totalCentavos: filas.fold(0, (s, v) => s + v.totalCentavos),
      );
    }).toList();
  }

  @override
  Future<VentaDetalle?> detalleVenta(int idVenta) async {
    final idCliente = _exigirSesion();
    final filas = ventas
        .where((v) => v.idVenta == idVenta && v.idCliente == idCliente)
        .toList();
    if (filas.isEmpty) return null;

    return VentaDetalle(
      resumen: VentaResumen(
        idVenta: idVenta,
        fecha: filas.first.fecha,
        lineas: filas.length,
        unidades: filas.fold(0, (s, v) => s + v.cantidad),
        totalCentavos: filas.fold(0, (s, v) => s + v.totalCentavos),
      ),
      lineas: filas
          .map(
            (v) => LineaVenta(
              producto: producto(v.idProducto).nombre,
              cantidad: v.cantidad,
              precioTotalCentavos: v.totalCentavos,
              nombreOferta: v.nombreOferta,
            ),
          )
          .toList(),
    );
  }

  // --------------- ESCRITURAS ---------------

  @override
  Future<int> registrarCliente({
    required String nombre,
    String? paterno,
    String? materno,
    String? telefono,
  }) async {
    // Como fn_registrar_cliente: si ya tiene ficha devuelve la suya, no crea
    // otra. Volver a entrar no multiplica clientes.
    final actual = _sesion;
    if (actual != null && clientes.containsKey(actual)) return actual;

    final id = _siguienteCliente++;
    clientes[id] = nombre;
    _sesion = id;
    return id;
  }

  VentaFake _escribirLineas({
    required int idCliente,
    required List<Map<String, Object?>> lineas,
  }) {
    final idVenta = _siguienteVenta++;
    final fecha = ahora();
    for (final l in lineas) {
      ventas.add(
        VentaFake(
          idVenta: idVenta,
          idCliente: idCliente,
          idProducto: l['id_producto']! as int,
          cantidad: l['cantidad']! as int,
          totalCentavos: l['pagado']! as int,
          fecha: fecha,
          nombreOferta: l['oferta'] as String?,
        ),
      );
    }
    return ventas.last;
  }

  @override
  Future<int> registrarVenta({
    required int idProducto,
    int cantidad = 1,
    int? idOferta,
  }) async {
    final idCliente = _exigirSesion();
    final indice = _productos.indexWhere((p) => p.idProducto == idProducto);
    if (indice < 0) {
      throw StateError('No existe el producto $idProducto');
    }
    final p = _productos[indice];

    if (p.stock < cantidad) {
      throw SinStockException('Sin stock de ${p.nombre}');
    }

    var unitario = p.precioCentavos;
    String? nombreOferta;

    if (idOferta != null) {
      // El servidor valida el limite aunque la app ya haya preguntado: entre
      // la pregunta y la compra el cliente pudo comprar desde otro sitio.
      if (!await puedeUsarOferta()) {
        throw LimiteOfertasException(
          'El cliente $idCliente ya uso su oferta de hoy',
        );
      }
      final escalera = _escaleras[idProducto] ?? const <EscalonOferta>[];
      final escalon = escalera.where((e) => e.idOferta == idOferta);
      if (escalon.isEmpty) {
        throw StateError('La oferta $idOferta no aplica al producto $idProducto');
      }
      unitario = escalon.first.precioFinalCentavos;
      nombreOferta = escalon.first.nombreOferta;
    }

    _productos[_productos.indexOf(p)] = p.copyWith(stock: p.stock - cantidad);

    final venta = _escribirLineas(
      idCliente: idCliente,
      lineas: [
        {
          'id_producto': idProducto,
          'cantidad': cantidad,
          'pagado': unitario * cantidad,
          'oferta': nombreOferta,
        },
      ],
    );
    return venta.idVenta;
  }

  // --------------- EL CARRITO (0011) ---------------
  //
  // Mismo contrato que fn_cotizar_carrito y fn_confirmar_carrito: cotizar
  // mira y avisa con banderas (no explota por stock); confirmar es todo o
  // nada y graba UNA venta con N lineas. Si este doble fuera mas permisivo
  // que el servidor, las pruebas pasarian y la app fallaria contra Supabase.

  @override
  Future<List<CotizacionLinea>> cotizarCarrito({
    required List<LineaCarrito> lineas,
  }) async {
    _exigirSesion();
    if (lineas.isEmpty) {
      throw StateError('El carrito esta vacio');
    }
    return [
      for (final l in lineas) _cotizarLinea(l.producto.idProducto, l.cantidad, l.idOferta),
    ];
  }

  CotizacionLinea _cotizarLinea(int idProducto, int cantidad, int? idOferta) {
    final p = producto(idProducto);
    var precio = p.precioCentavos;
    var aplicada = false;
    if (idOferta != null && _comprasDeHoy(_sesion!) < 2) {
      final escalon = (_escaleras[idProducto] ?? const <EscalonOferta>[])
          .where((e) => e.idOferta == idOferta);
      if (escalon.isNotEmpty) {
        precio = escalon.first.precioFinalCentavos;
        aplicada = true;
      }
    }
    return CotizacionLinea(
      idProducto: idProducto,
      cantidad: cantidad,
      idOferta: aplicada ? idOferta : null,
      precioUnitarioCentavos: precio,
      ofertaAplicada: aplicada,
      stockSuficiente: p.stock >= cantidad,
    );
  }

  @override
  Future<int> confirmarCarrito({
    required List<LineaCarrito> lineas,
  }) async {
    final idCliente = _exigirSesion();
    if (lineas.isEmpty) {
      throw StateError('El carrito esta vacio');
    }

    // Toda la confirmacion es UNA compra: el limite se mira una vez para el
    // carrito completo, no linea por linea.
    if (lineas.any((l) => l.idOferta != null)) {
      if (!await puedeUsarOferta()) {
        throw LimiteOfertasException(
          'El cliente $idCliente ya uso su oferta de hoy',
        );
      }
    }

    // Primero se valida TODO el carrito. Los stocks solo se descuentan
    // despues, cuando ya nada puede fallar: si se descontaran mientras se
    // valida, un carrito de dos lineas del mismo producto pasaria ambas
    // validaciones contra el stock original y se llevaria doble.
    final validadas = <(int, int, EscalonOferta?, int)>[];
    for (final l in lineas) {
      final p = producto(l.producto.idProducto);
      if (!p.activo) {
        throw StateError('El producto ${p.nombre} no esta activo');
      }
      if (p.stock < l.cantidad) {
        throw SinStockException('Sin stock suficiente de ${p.nombre}');
      }
      var unitario = p.precioCentavos;
      EscalonOferta? escalon;
      if (l.idOferta != null) {
        final escalones = (_escaleras[p.idProducto] ?? const <EscalonOferta>[])
            .where((e) => e.idOferta == l.idOferta);
        if (escalones.isEmpty) {
          throw StateError(
            'La oferta ${l.idOferta} no esta vigente para ${p.nombre}',
          );
        }
        escalon = escalones.first;
        unitario = escalon.precioFinalCentavos;
      }
      // El precio acordado no se le cree a nadie: si lo congelado en
      // pantalla difiere de lo que determina el catalogo, muere completo.
      if (l.acordadoCentavos != unitario) {
        throw PrecioCambioException(
          'El precio de ${p.nombre} cambio: acordaste '
          '${soles(l.acordadoCentavos)} y hoy vale ${soles(unitario)}',
        );
      }
      validadas.add((p.idProducto, l.cantidad, escalon, unitario));
    }

    final lineasVenta = <Map<String, Object?>>[];
    for (final (id, cant, escalon, unitario) in validadas) {
      final indice = _productos.indexWhere((p) => p.idProducto == id);
      _productos[indice] = _productos[indice].copyWith(stock: _productos[indice].stock - cant);
      lineasVenta.add({
        'id_producto': id,
        'cantidad': cant,
        'pagado': unitario * cant,
        'oferta': escalon?.nombreOferta,
      });
    }

    _escribirLineas(idCliente: idCliente, lineas: lineasVenta);
    return ventas.last.idVenta;
  }

  // --------------- AYUDAS PARA LAS PRUEBAS ---------------

  /// Deja a [idCliente] sin derecho a oferta, simulando que ya uso la de hoy
  /// (0013: la venta lleva nombreOferta; sin ella no consumiria el cupo).
  void agotarCupoDe(int idCliente) {
    ventas.add(
      VentaFake(
        idVenta: _siguienteVenta++,
        idCliente: idCliente,
        idProducto: _productos.first.idProducto,
        cantidad: 1,
        totalCentavos: 0,
        fecha: ahora(),
        nombreOferta: 'Oferta de prueba',
      ),
    );
  }

  Future<void> cerrar() async {
    await _controlador?.close();
    _controlador = null;
  }
}

/// Una fila de detalle de venta del doble. Las filas de una misma venta
/// comparten [idVenta]; [totalCentavos] es lo pagado por la LINEA, y el total
/// de la venta es la suma de sus filas (el historial lo junta asi).
class VentaFake {
  VentaFake({
    required this.idVenta,
    required this.idCliente,
    required this.idProducto,
    required this.cantidad,
    required this.totalCentavos,
    required this.fecha,
    this.nombreOferta,
  });

  final int idVenta;
  final int idCliente;
  final int idProducto;
  final int cantidad;
  final int totalCentavos;
  final DateTime fecha;
  final String? nombreOferta;
}
