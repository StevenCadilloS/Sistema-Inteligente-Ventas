import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/remote/sesion_service.dart';
import 'data/remote/supabase_config.dart';
import 'data/repositories/supabase_tienda_repository.dart';
import 'data/repositories/tienda_repository.dart';
import 'services/emotion_channel.dart';
import 'theme/app_theme.dart';
import 'ui/configuracion_faltante_screen.dart';
import 'ui/detector_test_screen.dart';
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

  // Variante totalmente local para evaluar el detector sin inicializar ni
  // requerir Supabase. GitHub Actions la publica como una APK separada.
  const modoPruebaDetector = bool.fromEnvironment('DETECTOR_TEST_MODE');
  if (modoPruebaDetector) {
    runApp(const DetectorTestApp());
    return;
  }

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
  final sesion = SesionService(Supabase.instance.client);
  final emotionChannel = EmotionChannel();

  runApp(
    MyApp(
      tienda: tienda,
      sesion: sesion,
      emotionChannel: emotionChannel,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.tienda,
    required this.sesion,
    required this.emotionChannel,
  });

  final TiendaRepository tienda;
  final SesionService sesion;
  final EmotionChannel emotionChannel;

  @override
  Widget build(BuildContext context) {
    // El SDK de Supabase restaura la sesion guardada al arrancar, asi que
    // quien ya entro una vez no vuelve a ver el login.
    final haySesion = sesion.haySesion;

    return MaterialApp(
      title: 'Tienda Adaptativa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: haySesion ? '/tienda' : '/',
      routes: {
        '/': (context) => LoginScreen(sesion: sesion, tienda: tienda),
        '/tienda': (context) => TiendaScreen(
          sesion: sesion,
          emotionChannel: emotionChannel,
          tienda: tienda,
        ),
        '/historial': (context) => HistorialScreen(tienda: tienda),
      },
    );
  }
}
