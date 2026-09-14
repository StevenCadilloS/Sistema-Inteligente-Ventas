import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/ui/widgets/carrito_hoja.dart';

/// Pruebas de la hoja del carrito: lo que pinta y a quien avisa.
///
/// El flujo/pizarra completo (cotizar, avisar por precio cambiado, cobrar)
/// esta cubierto en tienda_screen_test.dart; aqui solo importan las
/// interacciones de edicion que el cliente va a usar: ajustar, eliminar,
/// vaciar.
void main() {
  Producto p(int id, String nombre, int precio) => Producto(
    idProducto: id,
    nombre: nombre,
    precioCentavos: precio,
    stock: 10,
  );

  LineaCarrito linea(
    int id,
    String nombre,
    int precio, {
    int cantidad = 1,
    int? idOferta,
    int? acordado,
  }) => LineaCarrito(
    producto: p(id, nombre, precio),
    cantidad: cantidad,
    idOferta: idOferta,
    acordadoCentavos: acordado ?? precio,
  );

  late List<(LineaCarrito, int)> ajustes;
  late List<LineaCarrito> eliminadas;
  var confirmo = false;
  var siguio = false;

  Future<void> montar(
    WidgetTester tester,
    List<LineaCarrito> lineas, {
    bool confirmando = false,
  }) async {
    ajustes = [];
    eliminadas = [];
    confirmo = false;
    siguio = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => CarritoHoja(
                lineas: lineas,
                confirmando: confirmando,
                onCantidad: (l, n) => ajustes.add((l, n)),
                onEliminar: (l) => eliminadas.add(l),
                onVaciar: () {},
                onConfirmar: () => confirmo = true,
                onSeguirComprando: () => siguio = true,
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    // Con confirmando=true aparece un spinner infinito: no hay un frame de
    // reposo al que llegar, y pumpAndSettle solo se acabaria al timeout.
    if (confirmando) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    } else {
      await tester.pumpAndSettle();
    }
  }

  testWidgets('vacia: explica como se llena', (tester) async {
    await montar(tester, const []);

    expect(find.text('Tu carrito esta vacio'), findsOneWidget);
    expect(find.text('Confirmar compra'), findsNothing);
  });

  testWidgets('pinta el total como la suma de las lineas', (tester) async {
    final l1 = linea(1, 'Mouse', 12000, cantidad: 2);
    final l2 = linea(2, 'Laptop', 225000, idOferta: 7, acordado: 225000);

    await montar(tester, [l1, l2]);

    // 24000 + 225000 = 249000 = S/2490.00
    expect(find.text('S/2490.00'), findsOneWidget);
    expect(find.text('Tu carrito'), findsOneWidget);
  });

  testWidgets('el mas suma una unidad', (tester) async {
    final l = linea(1, 'Mouse', 12000, cantidad: 2, idOferta: 7);

    await montar(tester, [l]);

    await tester.tap(find.byTooltip('Agregar una unidad'));
    await tester.pumpAndSettle();
    expect(ajustes.single.$2, 3);
  });

  testWidgets('el menos a la ultima unidad elimina la linea', (tester) async {
    final l = linea(1, 'Mouse', 12000, cantidad: 1);

    await montar(tester, [l]);

    await tester.tap(find.byTooltip('Quitar una unidad'));
    await tester.pumpAndSettle();
    expect(ajustes.single.$2, 0,
        reason: 'cantidad 0 significa quitar la linea entera');
  });

  testWidgets('confirmando apaga los botones de edicion', (tester) async {
    final l = linea(1, 'Mouse', 12000, cantidad: 2);

    await montar(tester, [l], confirmando: true);

    expect(tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.add_circle_outline),
        matching: find.byType(IconButton),
      ),
    ).onPressed, isNull);
    // La hoja, no el boton "abrir" que la levanta (tambien es un
    // FilledButton, y es el que hacia fallar el byType suelto).
    final enLaHoja = find.descendant(
      of: find.byType(CarritoHoja),
      matching: find.byType(FilledButton),
    );
    expect(enLaHoja, findsOneWidget);
    expect(tester.widget<FilledButton>(enLaHoja).onPressed, isNull,
        reason: 'con la confirmacion en vuelo no se vuelve a confirmar');
    // Y el boton muestra el spinner, no su texto: por eso el finder por
    // texto ya no existe cuando confirmando=true.
    expect(find.descendant(
      of: find.byType(CarritoHoja),
      matching: find.text('Confirmar compra'),
    ), findsNothing);
  });

  testWidgets('Seguir comprando avisa y no confirma', (tester) async {
    final l = linea(1, 'Mouse', 12000);

    await montar(tester, [l]);

    await tester.tap(find.text('Seguir comprando'));
    await tester.pumpAndSettle();
    expect(siguio, isTrue);
    expect(confirmo, isFalse);
  });
}
