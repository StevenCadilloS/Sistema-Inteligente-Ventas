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

    expect(find.text('Tenemos una actualizacion para ti'), findsOneWidget);

    await tester.tap(find.text('Actualizar'));
    expect(pulsado, isTrue);
  });
}
