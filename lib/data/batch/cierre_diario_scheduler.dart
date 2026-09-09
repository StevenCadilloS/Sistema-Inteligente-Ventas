import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../remote/supabase_config.dart';
import '../repositories/supabase_tienda_repository.dart';

/// Programador periodico del cierre diario (docs/PLAN_ELVIS.md fase 07).
///
/// El calculo ya no vive aqui: son los 6 procesos de `fn_cierre_diario()`, en
/// supabase/migrations/0002_funciones.sql. Al estar la base compartida, el
/// cierre tiene que recorrer las bitacoras de todos los usuarios, no las de
/// este telefono; esto es solo el disparador.
///
/// En produccion conviene programarlo en el servidor con pg_cron (una vez, en
/// vez de una vez por dispositivo instalado); el procedimiento esta en
/// supabase/README.md. Se mantiene el disparo desde la app porque es lo que
/// permite mostrarlo funcionando en la presentacion sin tocar el servidor, y
/// porque la funcion es idempotente: recalcula desde las bitacoras, asi que
/// varios disparos el mismo dia dan el mismo resultado que uno.
const cierreDiarioTaskName = 'cierre_diario';

/// Punto de entrada que WorkManager invoca en un isolate aparte cuando corre
/// la tarea en segundo plano. Debe quedar top-level (no en una clase) para que
/// el motor nativo lo pueda referenciar.
///
/// Ese isolate no comparte nada con el de la app: hay que inicializar Supabase
/// otra vez, porque `Supabase.instance` alli no existe.
@pragma('vm:entry-point')
void cierreDiarioCallbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != cierreDiarioTaskName) return true;
    if (!SupabaseConfig.configurado) return false;

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.clavePublica,
    );

    try {
      await SupabaseTiendaRepository(
        Supabase.instance.client,
      ).ejecutarCierreDiario();
      return true;
    } catch (_) {
      // Devolver false le pide a WorkManager que reintente: un cierre perdido
      // por quedarse sin cobertura se recupera solo en el siguiente intento.
      return false;
    }
  });
}

/// Registra el cierre diario para correr una vez al dia. Llamar una sola vez,
/// en el arranque de la app.
Future<void> programarCierreDiario() async {
  await Workmanager().initialize(cierreDiarioCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    cierreDiarioTaskName,
    cierreDiarioTaskName,
    frequency: const Duration(days: 1),
    // Ahora el cierre necesita red: sin conexion no hay a que base llamar.
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
  );
}
