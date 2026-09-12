import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/theme/app_theme.dart';
import 'package:tienda_adaptativa/ui/widgets/imagen_producto.dart';
import 'package:tienda_adaptativa/ui/widgets/producto_card.dart';

/// La tarjeta del feed. Tiene mas ramas de las que parece: tres etiquetas de
/// estado que se excluyen, el aviso de negociable, y el stock que cambia de
/// color al quedar poco.
void main() {
  Producto p({
    int id = 1,
    String nombre = 'Laptop Lenovo IdeaPad',
    int precio = 250000,
    int stock = 10,
    bool ofertas = false,
    String? imagen,
    String? categoria = 'Laptops',
  }) => Producto(
    idProducto: id,
    nombre: nombre,
    precioCentavos: precio,
    stock: stock,
    tieneOfertas: ofertas,
    imagen: imagen,
    categoria: categoria,
  );

  Future<void> montar(
    WidgetTester tester,
    Producto producto, {
    bool destacado = false,
    bool seleccionado = false,
    bool comprado = false,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 300,
            child: ProductoCard(
              producto: producto,
              destacado: destacado,
              seleccionado: seleccionado,
              comprado: comprado,
              estilo: EmotionStyle.of('neutral'),
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('lo basico', () {
    testWidgets('muestra nombre y precio', (tester) async {
      await montar(tester, p());

      expect(find.text('Laptop Lenovo IdeaPad'), findsOneWidget);
      expect(find.text('S/2500.00'), findsOneWidget);
    });

    testWidgets('el precio sale de centavos, sin redondeos raros', (tester) async {
      // 12345 centavos son S/123.45, no S/123.44999999.
      await montar(tester, p(precio: 12345));

      expect(find.text('S/123.45'), findsOneWidget);
    });

    testWidgets('avisa al pulsar', (tester) async {
      var pulsado = false;
      await montar(tester, p(), onTap: () => pulsado = true);

      await tester.tap(find.byType(ProductoCard));
      expect(pulsado, isTrue);
    });
  });

  group('el aviso de negociable', () {
    testWidgets('aparece si el producto tiene ofertas', (tester) async {
      await montar(tester, p(ofertas: true));

      expect(find.text('Negociable'), findsOneWidget);
    });

    testWidgets('no aparece sin ofertas', (tester) async {
      await montar(tester, p(ofertas: false));

      expect(find.text('Negociable'), findsNothing);
    });

    testWidgets('no adelanta de cuanto es el descuento', (tester) async {
      await montar(tester, p(ofertas: true));

      // Decir "-30%" en el feed haria que nadie se quedara en el 10%: el
      // escalon que toca se decide durante la negociacion.
      expect(find.textContaining('%'), findsNothing);
    });
  });

  group('etiquetas de estado', () {
    testWidgets('seleccionado gana a comprado y destacado', (tester) async {
      await montar(tester, p(), seleccionado: true, comprado: true,
          destacado: true);

      expect(find.text('Seleccionado'), findsOneWidget);
      expect(find.text('Comprado'), findsNothing);
      expect(find.text('Para ti'), findsNothing);
    });

    testWidgets('comprado gana a destacado', (tester) async {
      await montar(tester, p(), comprado: true, destacado: true);

      expect(find.text('Comprado'), findsOneWidget);
      expect(find.text('Para ti'), findsNothing);
    });

    testWidgets('sin ningun estado no hay etiqueta', (tester) async {
      await montar(tester, p());

      expect(find.text('Seleccionado'), findsNothing);
      expect(find.text('Comprado'), findsNothing);
      expect(find.text('Para ti'), findsNothing);
    });
  });

  group('stock', () {
    testWidgets('con pocas unidades avisa cuantas quedan', (tester) async {
      await montar(tester, p(stock: 2));

      expect(find.text('Quedan 2'), findsOneWidget);
    });

    testWidgets('con tres queda en el umbral de aviso', (tester) async {
      await montar(tester, p(stock: 3));

      expect(find.text('Quedan 3'), findsOneWidget);
    });

    testWidgets('con cuatro ya se cuenta como disponible', (tester) async {
      await montar(tester, p(stock: 4));

      expect(find.text('4 disponibles'), findsOneWidget);
    });
  });

  group('agotado', () {
    testWidgets('sin stock muestra la franja y el texto', (tester) async {
      await montar(tester, p(stock: 0));

      expect(find.text('AGOTADO'), findsOneWidget);
      expect(find.text('Agotado'), findsOneWidget);
    });

    testWidgets('con stock no muestra la franja', (tester) async {
      await montar(tester, p(stock: 1));

      expect(find.text('AGOTADO'), findsNothing);
    });

    testWidgets('sin stock no se puede pulsar', (tester) async {
      var pulsado = false;
      await montar(tester, p(stock: 0), onTap: () => pulsado = true);

      await tester.tap(find.byType(ProductoCard));
      expect(pulsado, isFalse);
    });

    testWidgets('sin stock no ofrece negociar aunque tenga ofertas', (tester) async {
      // Nada que negociar si no hay unidades que vender.
      await montar(tester, p(stock: 0, ofertas: true));

      expect(find.text('Negociable'), findsNothing);
    });
  });

  group('imagen', () {
    testWidgets('sin imagen cae al icono de la categoria', (tester) async {
      await montar(tester, p(imagen: null));

      // ImagenProducto devuelve el respaldo, que la tarjeta define como el
      // icono de categoria.
      expect(find.byType(ImagenProducto), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('dos productos de la misma categoria comparten icono', (tester) async {
      // El icono sale del hash de la categoria: dos productos de "Laptops"
      // tienen que verse igual, o el feed parece desordenado.
      await montar(tester, p(id: 1, categoria: 'Laptops'));
      final primero = tester.widget<Icon>(find.byType(Icon).first).icon;

      await montar(tester, p(id: 2, categoria: 'Laptops'));
      final segundo = tester.widget<Icon>(find.byType(Icon).first).icon;

      expect(primero, segundo);
    });
  });
}
