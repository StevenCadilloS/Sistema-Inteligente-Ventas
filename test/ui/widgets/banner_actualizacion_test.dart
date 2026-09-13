import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/ui/widgets/banner_actualizacion.dart';

void main() {
  testWidgets('muestra el aviso y avisa al pulsar Actualizar', (
    tester,
  ) async {
    var pulsado = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BannerActualizacion(onActualizar: () => pulsado = true),
        ),
      ),
    );

    expect(find.text('Actualizacion disponible'), findsOneWidget);
    expect(find.text('Hay una version nueva de la tienda'), findsOneWidget);

    await tester.tap(find.text('Actualizar'));
    expect(pulsado, isTrue);
  });
}
