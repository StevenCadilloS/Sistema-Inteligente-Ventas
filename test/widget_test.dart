// Smoke test de arranque de la app. El original de `flutter create` probaba
// el contador de la plantilla, que ya no existe desde que main.dart quedo
// conectado a ClienteRepository/AdaptationEngine/BanditOptimizer (commit
// "Pantallas").

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tienda_adaptativa/data/database/app_database.dart';
import 'package:tienda_adaptativa/data/repositories/cliente_repository.dart';
import 'package:tienda_adaptativa/decision/adaptation_engine.dart';
import 'package:tienda_adaptativa/decision/learning/bandit_optimizer.dart';
import 'package:tienda_adaptativa/main.dart';
import 'package:tienda_adaptativa/services/emotion_channel.dart';

void main() {
  testWidgets('sin sesion activa, la app arranca en la pantalla de login',
      (WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').getSingle(); // dispara onCreate/seed
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final clienteRepository = ClienteRepository(db, prefs);
    final bandit = BanditOptimizer(db);
    final adaptationEngine = AdaptationEngine(db, bandit);
    final emotionChannel = EmotionChannel();

    await tester.pumpWidget(MyApp(
      db: db,
      clienteRepository: clienteRepository,
      adaptationEngine: adaptationEngine,
      bandit: bandit,
      emotionChannel: emotionChannel,
    ));

    expect(find.text('Registrarse'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Ingresar'), findsOneWidget);

    await db.close();
  });
}
