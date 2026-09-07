import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/batch/cierre_diario_scheduler.dart';
import 'data/database/app_database.dart';
import 'data/database/demo_seed.dart';
import 'data/repositories/cliente_repository.dart';
import 'decision/adaptation_engine.dart';
import 'decision/learning/bandit_optimizer.dart';
import 'services/emotion_channel.dart';
import 'theme/app_theme.dart';
import 'ui/login_screen.dart';
import 'ui/principal_screen.dart';
import 'ui/historial_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await programarCierreDiario();

  final db = AppDatabase();
  await sembrarCatalogoDemo(db);
  final prefs = await SharedPreferences.getInstance();

  final clienteRepository = ClienteRepository(db, prefs);
  final bandit = BanditOptimizer(db);
  final adaptationEngine = AdaptationEngine(db, bandit);
  final emotionChannel = EmotionChannel();

  runApp(MyApp(
    db: db,
    clienteRepository: clienteRepository,
    adaptationEngine: adaptationEngine,
    bandit: bandit,
    emotionChannel: emotionChannel,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.db,
    required this.clienteRepository,
    required this.adaptationEngine,
    required this.bandit,
    required this.emotionChannel,
  });

  final AppDatabase db;
  final ClienteRepository clienteRepository;
  final AdaptationEngine adaptationEngine;
  final BanditOptimizer bandit;
  final EmotionChannel emotionChannel;

  @override
  Widget build(BuildContext context) {
    final clienteActivo = clienteRepository.clienteActivo();

    return MaterialApp(
      title: 'Tienda Adaptativa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: clienteActivo != null ? '/principal' : '/',
      routes: {
        '/': (context) => LoginScreen(clienteRepository: clienteRepository),
        '/principal': (context) => PrincipalScreen(
              clienteRepository: clienteRepository,
              adaptationEngine: adaptationEngine,
              banditOptimizer: bandit,
              emotionChannel: emotionChannel,
            ),
        '/historial': (context) => HistorialScreen(db: db),
      },
    );
  }
}
