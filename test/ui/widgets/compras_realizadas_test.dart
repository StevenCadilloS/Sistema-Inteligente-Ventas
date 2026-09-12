import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/ui/widgets/compras_realizadas.dart';

/// Lo que ve el cliente al abrir el carrito. No es un carrito pendiente: cada
/// linea ya se registro como venta, asi que el total que muestra tiene que
/// cuadrar con lo que se cobro de verdad.
void main() {
  Producto p(int id, String nombre, int precio) => Producto(
    idProducto: id,
    nombre: nombre,
    precioCentavos: precio,
    stock: 10,
  );

  Future<void> montar(WidgetTester tester, List<CompraRealizada> compras) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ComprasRealizadas(compras: compras))),
    );
    await tester.pumpAndSettle();
  }

  group('sin compras', () {
    testWidgets('lo dice en vez de mostrar una lista vacia', (tester) async {
      await montar(tester, const []);

      expect(find.text('Aun no compraste nada'), findsOneWidget);
    });
  });

  group('con compras', () {
    testWidgets('una linea por compra', (tester) async {
      await montar(tester, [
        (producto: p(1, 'Laptop Lenovo', 250000), pagadoCentavos: 200000),
        (producto: p(2, 'Mouse Logitech', 12000), pagadoCentavos: 12000),
      ]);

      expect(find.text('Laptop Lenovo'), findsOneWidget);
      expect(find.text('Mouse Logitech'), findsOneWidget);
    });

    testWidgets('muestra lo pagado, no el precio de lista', (tester) async {
      await montar(tester, [
        (producto: p(1, 'Laptop Lenovo', 250000), pagadoCentavos: 200000),
      ]);

      // Aparece dos veces: en la linea y en el total, que con una sola compra
      // coinciden.
      expect(find.text('S/2000.00'), findsNWidgets(2));
    });

    testWidgets('con descuento se anuncia el precio de lista', (tester) async {
      await montar(tester, [
        (producto: p(1, 'Laptop Lenovo', 250000), pagadoCentavos: 200000),
      ]);

      // El tachado es lo que justifica el descuento: sin el, el cliente no
      // sabe cuanto se ahorro.
      expect(find.textContaining('S/2500.00'), findsOneWidget);
    });

    testWidgets('sin descuento no se anuncia nada tachado', (tester) async {
      await montar(tester, [
        (producto: p(2, 'Mouse Logitech', 12000), pagadoCentavos: 12000),
      ]);

      // Pago el precio de lista: no hay ahorro que ensenar.
      expect(find.textContaining('Precio de lista'), findsNothing);
    });

    testWidgets('el mismo producto dos veces sale dos veces', (tester) async {
      // Se compro a dos precios distintos, en dos negociaciones: son dos
      // lineas, no una agrupada.
      await montar(tester, [
        (producto: p(1, 'Laptop Lenovo', 250000), pagadoCentavos: 250000),
        (producto: p(1, 'Laptop Lenovo', 250000), pagadoCentavos: 175000),
      ]);

      expect(find.text('Laptop Lenovo'), findsNWidgets(2));
      expect(find.text('S/2500.00'), findsWidgets);
      expect(find.text('S/1750.00'), findsOneWidget);
    });
  });

  group('el total', () {
    testWidgets('suma lo pagado, no los precios de lista', (tester) async {
      await montar(tester, [
        (producto: p(1, 'Laptop Lenovo', 250000), pagadoCentavos: 200000),
        (producto: p(2, 'Mouse Logitech', 12000), pagadoCentavos: 10800),
      ]);

      // 200000 + 10800 = 210800. Si sumara los de lista serian 262000, y el
      // cliente veria un total que nunca pago.
      expect(find.text('S/2108.00'), findsOneWidget);
    });

    testWidgets('con una sola compra el total es esa compra', (tester) async {
      await montar(tester, [
        (producto: p(2, 'Mouse Logitech', 12000), pagadoCentavos: 12000),
      ]);

      expect(find.text('S/120.00'), findsWidgets);
    });
  });
}
