import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/remote/supabase_config.dart';
import 'data/repositories/cliente_repository.dart';
import 'data/repositories/supabase_tienda_repository.dart';
import 'data/repositories/tienda_repository.dart';
import 'services/emotion_channel.dart';
import 'theme/app_theme.dart';
import 'ui/configuracion_faltante_screen.dart';
import 'ui/historial_screen.dart';
import 'ui/login_screen.dart';
import 'ui/tienda_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo vertical: en horizontal la camara frontal queda a un costado y el
  // rostro se sale del encuadre, que es de donde sale todo el contexto.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Sin backend no hay catalogo, y sin catalogo no hay nada que adaptar. Se
  // avisa con una pantalla que explica que falta, en vez de arrancar y
  // reventar con un error de red que no dice nada.
  if (!SupabaseConfig.configurado) {
    runApp(const AppSinBackend());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.clavePublica,
  );

  final tienda = SupabaseTiendaRepository(Supabase.instance.client);
  final prefs = await SharedPreferences.getInstance();

  final clienteRepository = ClienteRepository(tienda, prefs);
  final emotionChannel = EmotionChannel();

  runApp(
    MyApp(
      tienda: tienda,
      clienteRepository: clienteRepository,
      emotionChannel: emotionChannel,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.tienda,
    required this.clienteRepository,
    required this.emotionChannel,
  });

  final TiendaRepository tienda;
  final ClienteRepository clienteRepository;
  final EmotionChannel emotionChannel;

  @override
  Widget build(BuildContext context) {
    final clienteActivo = clienteRepository.clienteActivo();

    return MaterialApp(
      title: 'Tienda Adaptativa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: clienteActivo != null ? '/tienda' : '/',
      routes: {
        '/': (context) => LoginScreen(clienteRepository: clienteRepository),
        '/tienda': (context) => TiendaScreen(
          clienteRepository: clienteRepository,
          emotionChannel: emotionChannel,
          tienda: tienda,
        ),
        '/historial': (context) =>
            HistorialScreen(tienda: tienda, clienteRepository: clienteRepository),
      },
    );
  }
}
