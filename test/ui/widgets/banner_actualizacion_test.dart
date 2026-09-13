import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/ui/widgets/banner_actualizacion.dart';

void main() {
  Future<void> montar(
    WidgetTester tester, {
    VoidCallback? onActualizar,
    double? avance,
    String? error,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BannerActualizacion(
          onActualizar: onActualizar ?? () {},
          avance: avance,
          error: error,
        ),
      ),
    ),
  );

  group('en reposo', () {
    testWidgets('muestra el aviso y avisa al pulsar Actualizar', (
      tester,
    ) async {
      var pulsado = false;
      await montar(tester, onActualizar: () => pulsado = true);

      expect(find.text('Actualizacion disponible'), findsOneWidget);
      expect(find.text('Hay una version nueva de la tienda'), findsOneWidget);

      await tester.tap(find.text('Actualizar'));
      expect(pulsado, isTrue);
    });
  });

  group('descargando', () {
    testWidgets('muestra el porcentaje y esconde el boton', (tester) async {
      await montar(tester, avance: 0.42);

      expect(find.text('42%'), findsOneWidget);
      expect(find.text('Descargando la actualizacion'), findsOneWidget);
      // Sin boton: volver a pulsar lanzaria una segunda descarga.
      expect(find.text('Actualizar'), findsNothing);
    });

    testWidgets('sin tamano conocido, la barra va indeterminada', (
      tester,
    ) async {
      await montar(tester, avance: -1);

      final barra = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(barra.value, isNull);
      expect(find.text('Espera un momento...'), findsOneWidget);
    });
  });

  group('tras un fallo', () {
    testWidgets('explica el fallo y ofrece reintentar', (tester) async {
      await montar(tester, error: 'No se pudo descargar.');

      expect(find.text('No se pudo descargar.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Actualizar'), findsNothing);
    });
  });
}
