import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/ui/widgets/banner_esperando.dart';

Widget _app(BannerEsperando banner) {
  return MaterialApp(home: Scaffold(body: banner));
}

void main() {
  testWidgets('no afirma que la camara lee antes de elegir un producto', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const BannerEsperando(
          negociando: false,
          camaraEncendida: false,
          detectando: false,
        ),
      ),
    );

    expect(
      find.text('Selecciona un producto para iniciar la evaluacion facial.'),
      findsOneWidget,
    );
  });

  testWidgets('explica que Android debe solicitar el permiso', (tester) async {
    await tester.pumpWidget(
      _app(
        const BannerEsperando(
          negociando: true,
          camaraEncendida: true,
          detectando: false,
        ),
      ),
    );

    expect(find.textContaining('Acepta el permiso'), findsOneWidget);
  });

  testWidgets('muestra el error de permiso recibido', (tester) async {
    await tester.pumpWidget(
      _app(
        const BannerEsperando(
          negociando: true,
          camaraEncendida: false,
          detectando: false,
          errorCamara: 'Camara bloqueada.',
        ),
      ),
    );

    expect(find.text('Camara bloqueada.'), findsOneWidget);
    expect(find.byIcon(Icons.no_photography_outlined), findsOneWidget);
  });
}
