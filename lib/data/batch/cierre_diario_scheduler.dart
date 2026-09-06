import 'package:workmanager/workmanager.dart';

import '../database/app_database.dart';
import 'batch_runner.dart';

/// Programador periodico del cierre diario (docs/PLAN_ELVIS.md fase 07).
/// El entregable real es `BatchRunner.ejecutarCierreDiario()` ejecutable a
/// demanda (por ejemplo desde un boton en la pantalla de historial, para
/// la presentacion); esto solo automatiza dispararlo una vez al dia en
/// segundo plano.
const cierreDiarioTaskName = 'cierre_diario';

/// Punto de entrada que WorkManager invoca en un isolate aparte cuando
/// corre la tarea en segundo plano. Debe quedar top-level (no en una
/// clase) para que el motor nativo lo pueda referenciar.
@pragma('vm:entry-point')
void cierreDiarioCallbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != cierreDiarioTaskName) return true;

    final db = AppDatabase();
    try {
      await BatchRunner(db).ejecutarCierreDiario();
      return true;
    } finally {
      await db.close();
    }
  });
}

/// Registra el cierre diario para correr una vez al dia. Llamar una sola
/// vez, en el arranque de la app.
Future<void> programarCierreDiario() async {
  await Workmanager().initialize(cierreDiarioCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    cierreDiarioTaskName,
    cierreDiarioTaskName,
    frequency: const Duration(days: 1),
    constraints: Constraints(requiresBatteryNotLow: true),
  );
}
