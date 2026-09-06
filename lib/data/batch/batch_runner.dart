import '../database/app_database.dart';

/// Cierre diario del Modulo Batch (docs/PLAN_ELVIS.md fase 07 - cero
/// puntos de rubrica, valor de presentacion). Actualiza los contadores
/// derivados de `estrategias`, `clientes` y `productos` a partir de
/// `interacciones`/`ventas`.
///
/// Estos 6 procesos van en **una sola transaccion**: o se actualizan
/// todos, o no se actualiza ninguno (regla explicita de
/// docs/Consideraciones.docx). D1: `totalVecesAplicada` agrupa por
/// `codEstrategia`, no por `codCliente` como decia el diagrama original
/// del Modulo Batch (docs/ESQUEMA_CORREGIDO.md D1).
///
/// Nota: esto es independiente del aprendizaje UCB1 (fase 06), que
/// recalcula exitos/intentos EN VIVO por su cuenta y nunca lee ni escribe
/// estas mismas columnas - ver lib/decision/learning/bandit_optimizer.dart.
class BatchRunner {
  BatchRunner(this._db);

  final AppDatabase _db;

  Future<void> ejecutarCierreDiario() {
    return _db.transaction(() async {
      await _db.batchActualizarTotalVecesAplicada();
      await _db.batchActualizarVentasGeneradas();
      await _db.batchActualizarCantLecturas();
      await _db.batchActualizarTotalesCliente();
      await _db.batchActualizarCierresVenta(); // D3
      await _db.batchActualizarTotalVendidos();
    });
  }
}
