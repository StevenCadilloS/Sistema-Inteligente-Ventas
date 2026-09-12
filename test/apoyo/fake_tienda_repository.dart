import 'dart:async';

import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/data/repositories/tienda_repository.dart';

/// Doble en memoria de [TiendaRepository].
///
/// Replica lo que hacen las funciones del servidor, incluidas las reglas que
/// importan: el limite de dos ofertas por dia, el descuento de stock y el
/// calculo del precio de cada escalon. Si este doble fuera mas permisivo que
/// el servidor, las pruebas pasarian y la app fallaria contra la base real.
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
    return id != null && _comprasDeHoy(id) < 2;
  }

  @override
  Future<int?> clienteActual() async => _sesion;

  int _comprasDeHoy(int idCliente) {
    final hoy = ahora();
    return ventas
        .where(
          (v) =>
              v.idCliente == idCliente &&
              v.fecha.year == hoy.year &&
              v.fecha.month == hoy.month &&
              v.fecha.day == hoy.day,
        )
        .length;
  }

  @override
  Future<List<CompraHistorial>> historial({int limite = 50}) async {
    final idCliente = _exigirSesion();
    return ventas
        .where((v) => v.idCliente == idCliente)
        .take(limite)
        .map(
          (v) => CompraHistorial(
            idVenta: v.idVenta,
            fecha: v.fecha,
            producto: producto(v.idProducto).nombre,
            cantidad: v.cantidad,
            totalCentavos: v.totalCentavos,
            nombreOferta: v.nombreOferta,
          ),
        )
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
    // Como fn_registrar_cliente: si ya tiene ficha devuelve la suya, no crea
    // otra. Volver a entrar no multiplica clientes.
    final actual = _sesion;
    if (actual != null && clientes.containsKey(actual)) return actual;

    final id = _siguienteCliente++;
    clientes[id] = nombre;
    _sesion = id;
    return id;
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
          'El cliente $idCliente ya uso sus dos ofertas de hoy',
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

    _productos[indice] = p.copyWith(stock: p.stock - cantidad);

    final venta = VentaFake(
      idVenta: _siguienteVenta++,
      idCliente: idCliente,
      idProducto: idProducto,
      cantidad: cantidad,
      totalCentavos: unitario * cantidad,
      fecha: ahora(),
      nombreOferta: nombreOferta,
    );
    ventas.add(venta);
    return venta.idVenta;
  }

  // --------------- AYUDAS PARA LAS PRUEBAS ---------------

  /// Deja a [idCliente] sin derecho a ofertas, simulando que ya compro dos
  /// veces hoy.
  void agotarCupoDe(int idCliente) {
    for (var i = 0; i < 2; i++) {
      ventas.add(
        VentaFake(
          idVenta: _siguienteVenta++,
          idCliente: idCliente,
          idProducto: _productos.first.idProducto,
          cantidad: 1,
          totalCentavos: 0,
          fecha: ahora(),
        ),
      );
    }
  }

  Future<void> cerrar() async {
    await _controlador?.close();
    _controlador = null;
  }
}

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
