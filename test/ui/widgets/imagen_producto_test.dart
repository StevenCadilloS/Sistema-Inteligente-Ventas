import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/ui/widgets/imagen_producto.dart';

/// `productos.imagen` admite dos formas: el nombre de un archivo empaquetado
/// en el APK, o una URL completa. Elegir mal significa pedir por red algo que
/// esta en disco, o al reves -- y en ambos casos la tarjeta se queda sin foto
/// sin decir por que.
void main() {
  Producto p(String? imagen) => Producto(
    idProducto: 1,
    nombre: 'Producto',
    precioCentavos: 1000,
    stock: 5,
    imagen: imagen,
  );

  Future<void> montar(WidgetTester tester, String? imagen) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: ImagenProducto(
              producto: p(imagen),
              respaldo: const Icon(Icons.image_not_supported),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('sin imagen', () {
    testWidgets('null muestra el respaldo', (tester) async {
      await montar(tester, null);

      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('cadena vacia tambien', (tester) async {
      await montar(tester, '');

      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });
  });

  group('elige entre red y disco', () {
    testWidgets('una URL https se pide por red', (tester) async {
      await montar(tester, 'https://ejemplo.com/foto.jpg');

      final imagen = tester.widget<Image>(find.byType(Image));
      expect(imagen.image, isA<NetworkImage>());
    });

    testWidgets('una URL http tambien', (tester) async {
      await montar(tester, 'http://ejemplo.com/foto.jpg');

      final imagen = tester.widget<Image>(find.byType(Image));
      expect(imagen.image, isA<NetworkImage>());
    });

    testWidgets('un nombre de archivo se busca en los assets', (tester) async {
      await montar(tester, 'laptop.jpg');

      final imagen = tester.widget<Image>(find.byType(Image));
      expect(imagen.image, isA<AssetImage>());
      expect((imagen.image as AssetImage).assetName,
          'assets/products/laptop.jpg');
    });

    testWidgets('un nombre que contiene http no es una URL', (tester) async {
      // "http_banner.jpg" empieza por http pero no es una URL: pedirlo por
      // red daria un error de host que la tarjeta no sabria explicar.
      await montar(tester, 'http_banner.jpg');

      final imagen = tester.widget<Image>(find.byType(Image));
      expect(imagen.image, isA<AssetImage>());
    });
  });
}
