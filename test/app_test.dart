// Smoke test de arranque de la app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tienda_adaptativa/data/repositories/cliente_repository.dart';
import 'package:tienda_adaptativa/decision/adaptation_engine.dart';
import 'package:tienda_adaptativa/decision/learning/bandit_optimizer.dart';
import 'package:tienda_adaptativa/main.dart';
import 'package:tienda_adaptativa/services/emotion_channel.dart';
import 'package:tienda_adaptativa/ui/configuracion_faltante_screen.dart';

import 'apoyo/fake_tienda_repository.dart';

void main() {
  testWidgets('sin sesion activa, la app arranca en la pantalla de login', (
    WidgetTester tester,
  ) async {
    final tienda = FakeTiendaRepository();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final clienteRepository = ClienteRepository(tienda, prefs);
    final bandit = BanditOptimizer(tienda);
    final adaptationEngine = AdaptationEngine(tienda, bandit);
    final emotionChannel = EmotionChannel();

    await tester.pumpWidget(
      MyApp(
        tienda: tienda,
        clienteRepository: clienteRepository,
        adaptationEngine: adaptationEngine,
        bandit: bandit,
        emotionChannel: emotionChannel,
      ),
    );

    expect(find.text('Registrarse'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Ingresar'), findsOneWidget);

    await tienda.cerrar();
  });

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
}
