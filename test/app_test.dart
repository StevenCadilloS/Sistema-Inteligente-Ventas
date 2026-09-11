// Smoke test de arranque de la app.

import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/ui/configuracion_faltante_screen.dart';

void main() {
  testWidgets('compilada sin credenciales, explica que falta el backend', (
    WidgetTester tester,
  ) async {
    // Es el tropiezo mas probable al clonar el repositorio: sin
    // --dart-define-from-file la app no tiene a donde conectarse. Debe decirlo
    // en pantalla, no quedarse en blanco.
    await tester.pumpWidget(const AppSinBackend());

    expect(find.text('Falta configurar el backend'), findsOneWidget);
    expect(
      find.textContaining('--dart-define-from-file=env.json'),
      findsOneWidget,
    );
  });

  // El arranque con sesion (MyApp, LoginScreen) necesita un SupabaseClient
  // vivo, porque SesionService envuelve auth directamente. Montarlo aqui
  // exigiria un servidor o un doble del SDK entero, y lo que se ganaria es
  // comprobar que una ruta apunta a la pantalla que dice su nombre. Lo que si
  // importa — que sin sesion no se pueda comprar, ver ofertas ni leer el
  // historial de otro — se prueba en tienda_repository_test.dart contra el
  // doble, y en supabase/tests/04_seguridad.sql contra PostgreSQL de verdad.
}
