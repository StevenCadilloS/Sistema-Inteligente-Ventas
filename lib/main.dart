import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/remote/actualizacion_service.dart';
import 'data/remote/descarga_apk.dart';
import 'data/remote/sesion_service.dart';
import 'data/remote/supabase_config.dart';
import 'data/repositories/supabase_tienda_repository.dart';
import 'data/repositories/tienda_repository.dart';
import 'services/emotion_channel.dart';
import 'theme/app_theme.dart';
import 'ui/configuracion_faltante_screen.dart';
import 'ui/historial_screen.dart';
import 'ui/login_screen.dart';
import 'ui/tienda_screen.dart';
import 'ui/widgets/banner_actualizacion.dart';

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

class MyApp extends StatefulWidget {
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
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _actualizaciones = ActualizacionService(Supabase.instance.client);
  ActualizacionDisponible? _actualizacion;

  bool _descargando = false;
  double _avance = 0;
  String? _errorDescarga;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _comprobarActualizacion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Igual que en TiendaScreen: quien deja la app abierta en segundo plano se
  // pierde el aviso de una version publicada mientras tanto si solo se
  // comprueba al arrancar. Revisar tambien al volver hace que llegue tan
  // pronto como se reabre la app, sin necesidad de notificaciones push.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _comprobarActualizacion();
  }

  Future<void> _comprobarActualizacion() async {
    final disponible = await _actualizaciones.comprobar();
    if (!mounted) return;
    setState(() => _actualizacion = disponible);
  }

  /// Descarga la APK y se la pasa al instalador del sistema.
  ///
  /// Antes esto solo abria el navegador. En un equipo la descarga llegaba al
  /// 100% y ahi se quedaba: el archivo no aparecia y el instalador no se
  /// abria nunca. Hacerlo desde la app permite ver el avance y saber que
  /// fallo; si aun asi falla, queda el navegador como salida.
  Future<void> _descargarEInstalar(String apkUrl) async {
    if (_descargando) return;

    setState(() {
      _descargando = true;
      _avance = 0;
      _errorDescarga = null;
    });

    try {
      await DescargaApk.descargarEInstalar(
        apkUrl,
        onAvance: (a) {
          if (mounted) setState(() => _avance = a);
        },
      );
      if (mounted) setState(() => _descargando = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _descargando = false;
        _errorDescarga = 'No se pudo descargar. Toca para reintentar.';
      });
      // Ultimo recurso: que lo intente el navegador.
      await launchUrl(Uri.parse(apkUrl), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // El SDK de Supabase restaura la sesion guardada al arrancar, asi que
    // quien ya entro una vez no vuelve a ver el login.
    final haySesion = widget.sesion.haySesion;

    return MaterialApp(
      title: 'Tienda Adaptativa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: haySesion ? '/tienda' : '/',
      routes: {
        '/': (context) =>
            LoginScreen(autenticacion: widget.sesion, tienda: widget.tienda),
        '/tienda': (context) => TiendaScreen(
          onCerrarSesion: widget.sesion.cerrarSesion,
          emotionChannel: widget.emotionChannel,
          tienda: widget.tienda,
        ),
        '/historial': (context) => HistorialScreen(tienda: widget.tienda),
      },
      // Envuelve cada ruta, no reemplaza ninguna: el banner se ve igual en
      // el login, la tienda o el historial, sin duplicar el chequeo en cada
      // pantalla.
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final actualizacion = _actualizacion;
        if (actualizacion == null) return child;

        return Column(
          children: [
            BannerActualizacion(
              onActualizar: () => _descargarEInstalar(actualizacion.apkUrl),
              avance: _descargando ? _avance : null,
              error: _errorDescarga,
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
