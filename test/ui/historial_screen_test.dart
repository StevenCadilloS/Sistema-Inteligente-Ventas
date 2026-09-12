import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/data/repositories/tienda_repository.dart';
import 'package:tienda_adaptativa/ui/historial_screen.dart';

import '../apoyo/fake_tienda_repository.dart';

/// La pantalla mas simple de la app: pide el historial y lo pinta. Aun asi
/// tiene tres caminos que el cliente puede ver --cargando, vacio, con error--
/// y ninguno estaba cubierto.

/// Repositorio que falla al pedir el historial, para probar ese camino.
class _RepoQueFalla extends FakeTiendaRepository {
  _RepoQueFalla(this.fallo);

  final Object fallo;

  @override
  Future<List<CompraHistorial>> historial({int limite = 50}) async {
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
    await tester.pumpWidget(MaterialApp(home: HistorialScreen(tienda: r)));
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
    testWidgets('pinta una fila por compra', (tester) async {
      await repo.registrarVenta(idProducto: 1, idOferta: 1);
      await repo.registrarVenta(idProducto: 2);

      await montar(tester, repo);

      expect(find.text('Laptop Lenovo IdeaPad'), findsOneWidget);
      expect(find.text('Mouse Logitech G203'), findsOneWidget);
    });

    testWidgets('distingue la compra con oferta de la normal', (tester) async {
      await repo.registrarVenta(idProducto: 1, idOferta: 1);
      await repo.registrarVenta(idProducto: 2);

      await montar(tester, repo);

      // La que uso oferta dice cual: es lo que explica por que dos compras
      // del mismo producto pueden costar distinto.
      expect(find.text('Descuento 20%'), findsOneWidget);
      expect(find.text('Precio normal'), findsOneWidget);
    });

    testWidgets('muestra el total que se pago, no el de lista', (tester) async {
      await repo.registrarVenta(idProducto: 1, idOferta: 1);

      await montar(tester, repo);

      expect(find.text('S/2000.00'), findsOneWidget,
          reason: 'se pago el escalon del 20%, no los S/2500 de lista');
      expect(find.text('S/2500.00'), findsNothing);
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
