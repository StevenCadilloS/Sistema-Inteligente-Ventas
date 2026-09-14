import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/data/repositories/tienda_repository.dart';
import 'package:tienda_adaptativa/ui/detalle_venta_screen.dart';

import '../apoyo/fake_tienda_repository.dart';

/// La pantalla que abre una tarjeta de "Mis compras": cabecera con la fecha y
/// el total de la venta, y debajo una linea por producto con lo que se pago.

class _RepoQueFalla extends FakeTiendaRepository {
  _RepoQueFalla(this.fallo);

  final Object fallo;

  @override
  Future<VentaDetalle?> detalleVenta(int idVenta) async {
    throw fallo;
  }
}

void main() {
  late FakeTiendaRepository repo;

  Producto p(int id, String nombre, int precio) => Producto(
    idProducto: id,
    nombre: nombre,
    precioCentavos: precio,
    stock: 10,
  );

  VentaResumen resumen = VentaResumen(
    idVenta: 1,
    fecha: DateTime(2026, 3, 5, 9, 5),
    lineas: 1,
    unidades: 1,
    totalCentavos: 0,
  );

  Future<void> montar(WidgetTester tester, TiendaRepository r) async {
    await tester.pumpWidget(
      MaterialApp(home: DetalleVentaScreen(tienda: r, venta: resumen)),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    repo = FakeTiendaRepository(
      productos: [
        p(1, 'Laptop Lenovo IdeaPad', 250000),
        p(2, 'Mouse Logitech G203', 12000),
      ],
      escaleras: {
        1: [
          const EscalonOferta(
            orden: 1,
            idOferta: 1,
            nombreOferta: 'Descuento 20%',
            tipo: 'Descuento',
            porcentajeDescuento: 20,
            precioFinalCentavos: 200000,
          ),
        ],
      },
    );
    await repo.registrarCliente(nombre: 'Ana');
  });

  tearDown(() => repo.cerrar());

  testWidgets('muestra cada linea con su oferta y su total', (tester) async {
    await repo.registrarVenta(idProducto: 1, idOferta: 1);
    resumen = (await repo.historial()).single;

    await montar(tester, repo);

    expect(find.text('Laptop Lenovo IdeaPad'), findsOneWidget);
    expect(find.text('Descuento 20%'), findsOneWidget);
    expect(find.text('Cantidad: 1'), findsOneWidget);
    // Una vez en la linea y otra en el total de la venta.
    expect(find.text('S/2000.00'), findsNWidgets(2));
  });

  testWidgets('el carrito entero se ve como las lineas que lo forman',
      (tester) async {
    await repo.confirmarCarrito(lineas: [
      LineaCarrito(
        producto: p(1, 'Laptop Lenovo IdeaPad', 250000),
        cantidad: 1,
        idOferta: 1,
        acordadoCentavos: 200000,
      ),
      LineaCarrito(
        producto: p(2, 'Mouse Logitech G203', 12000),
        cantidad: 2,
        idOferta: null,
        acordadoCentavos: 12000,
      ),
    ]);
    resumen = (await repo.historial()).single;

    await montar(tester, repo);

    expect(find.text('Laptop Lenovo IdeaPad'), findsOneWidget);
    expect(find.text('Mouse Logitech G203'), findsOneWidget);
    expect(find.text('Precio normal'), findsOneWidget);
    expect(find.text('Cantidad: 2'), findsOneWidget);
    // El total es el de la venta, no una suma nueva de la pantalla.
    expect(find.text('S/2240.00'), findsOneWidget);
  });

  testWidgets('la fecha de la cabecera viene rellena con ceros',
      (tester) async {
    repo.ahora = () => DateTime(2026, 3, 5, 9, 5);
    await repo.registrarVenta(idProducto: 2);
    resumen = (await repo.historial()).single;

    await montar(tester, repo);

    expect(find.text('05/03/2026 09:05'), findsOneWidget);
  });

  testWidgets('la venta que el servidor no devuelve se explica', (tester) async {
    // En la base real pasa cuando el id no existe o la venta es de otra
    // persona: fn_venta_detalle devuelve vacio, no un error.
    await montar(tester, repo);

    expect(find.textContaining('no esta disponible'), findsOneWidget);
  });

  testWidgets('el fallo del servidor se muestra, no se disfraza',
      (tester) async {
    final malo = _RepoQueFalla(Exception('sin conexion'));
    addTearDown(malo.cerrar);

    await montar(tester, malo);

    expect(find.textContaining('sin conexion'), findsOneWidget);
  });
}
