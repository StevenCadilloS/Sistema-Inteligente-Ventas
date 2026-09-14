import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/data/repositories/tienda_repository.dart';
import 'package:tienda_adaptativa/ui/detalle_venta_screen.dart';
import 'package:tienda_adaptativa/ui/historial_screen.dart';

import '../apoyo/fake_tienda_repository.dart';

/// La lista de "Mis compras" pinta una tarjeta por VENTA y al tocarla abre el
/// detalle. Antes pintaba una fila por linea de detalle: una compra con dos
/// productos se veia como dos tarjetas con el mismo total, que parecia un
/// doble cobro.

/// Repositorio que falla al pedir el historial, para probar ese camino.
class _RepoQueFalla extends FakeTiendaRepository {
  _RepoQueFalla(this.fallo);

  final Object fallo;

  @override
  Future<List<VentaResumen>> historial({int limite = 50}) async {
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

  Future<void> montar(WidgetTester tester, TiendaRepository r) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (context) => HistorialScreen(tienda: r),
          '/historial/detalle': (context) {
            final venta =
                ModalRoute.of(context)!.settings.arguments! as VentaResumen;
            return DetalleVentaScreen(tienda: r, venta: venta);
          },
        },
      ),
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

  group('sin compras', () {
    testWidgets('lo dice en vez de dejar la pantalla en blanco', (tester) async {
      await montar(tester, repo);

      expect(find.textContaining('Aun no'), findsOneWidget);
    });
  });

  group('con compras', () {
    testWidgets('pinta una tarjeta por venta', (tester) async {
      await repo.registrarVenta(idProducto: 1, idOferta: 1);
      await repo.registrarVenta(idProducto: 2);

      await montar(tester, repo);

      expect(find.text('Compra #1'), findsOneWidget);
      expect(find.text('Compra #2'), findsOneWidget);
    });

    testWidgets('el carrito entero es UNA tarjeta', (tester) async {
      // Dos lineas en la misma confirmacion: en la base es una sola venta,
      // y en la lista tiene que verse como una sola compra.
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

      await montar(tester, repo);

      expect(find.text('Compra #1'), findsOneWidget);
      expect(find.textContaining('Compra #'), findsOneWidget);
      expect(find.text('3 unidades'), findsOneWidget);
      // 200000 (laptop con oferta) + 12000*2 (mouses) = 224000 centavos.
      expect(find.text('S/2240.00'), findsOneWidget);
    });

    testWidgets('muestra el total que se pago, no el de lista', (tester) async {
      await repo.registrarVenta(idProducto: 1, idOferta: 1);

      await montar(tester, repo);

      expect(find.text('S/2000.00'), findsOneWidget,
          reason: 'se pago el escalon del 20%, no los S/2500 de lista');
      expect(find.text('S/2500.00'), findsNothing);
    });
  });

  group('al tocar una tarjeta', () {
    testWidgets('abre el detalle de esa venta', (tester) async {
      await repo.registrarVenta(idProducto: 1, idOferta: 1);

      await montar(tester, repo);

      await tester.tap(find.text('Compra #1'));
      await tester.pumpAndSettle();

      expect(find.byType(DetalleVentaScreen), findsOneWidget);
      expect(find.text('Laptop Lenovo IdeaPad'), findsOneWidget);
      expect(find.text('Descuento 20%'), findsOneWidget);
      // Una vez en la linea y otra en el total de la venta.
      expect(find.text('S/2000.00'), findsNWidgets(2));
    });
  });

  group('cuando el servidor falla', () {
    testWidgets('muestra el error en vez de una lista vacia', (tester) async {
      final malo = _RepoQueFalla(Exception('sin conexion'));
      addTearDown(malo.cerrar);

      await montar(tester, malo);

      expect(find.textContaining('sin conexion'), findsOneWidget);
    });

    testWidgets('sin sesion tambien se explica', (tester) async {
      final malo = _RepoQueFalla(const SinSesionException());
      addTearDown(malo.cerrar);

      await montar(tester, malo);

      // No puede quedarse en "no tienes compras": no es lo mismo no haber
      // comprado que no poder consultarlo.
      expect(find.textContaining('Aun no'), findsNothing);
    });
  });

  group('formato de la fecha', () {
    testWidgets('rellena con cero las cifras de un digito', (tester) async {
      // Sin el relleno, una compra del 5 de marzo a las 9:05 se veia como
      // "5/3/2026 9:5", que parece un dato corrupto.
      repo.ahora = () => DateTime(2026, 3, 5, 9, 5);
      await repo.registrarVenta(idProducto: 2);

      await montar(tester, repo);

      expect(find.text('05/03/2026 09:05'), findsOneWidget);
    });

    testWidgets('las cifras de dos digitos no cambian', (tester) async {
      repo.ahora = () => DateTime(2026, 12, 25, 18, 42);
      await repo.registrarVenta(idProducto: 2);

      await montar(tester, repo);

      expect(find.text('25/12/2026 18:42'), findsOneWidget);
    });
  });
}
