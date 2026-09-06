import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';

/// Aprendizaje Multi-Armed Bandit (UCB1) sobre `estrategias`
/// (docs/PLAN_ELVIS.md fase 06). Reemplaza el placeholder de exploracion
/// que dejo AdaptationEngine en la fase 05.
///
/// exitos/intentos se recalculan EN VIVO desde `ventas`/`interacciones` en
/// cada seleccion (Estrategia A "recalculado al vuelo" de
/// docs/MODELO_ANDROID_ROOM.md §2.3) - deliberadamente NO se leen ni se
/// escriben las columnas derivadas `estrategias.ventasGeneradas` /
/// `totalVecesAplicada`, que quedan exclusivas del batch periodico (fase
/// 07, para los KPIs de presentacion). Mezclar ambas fuentes para el mismo
/// dato haria que se pisen entre si (docs/PLAN_ELVIS.md seccion 6).
class BanditOptimizer {
  BanditOptimizer(this._db);

  final AppDatabase _db;

  /// Elige la estrategia activa con mejor score UCB1. Una estrategia que
  /// nunca se aplico se prioriza sobre el score (exploracion antes que
  /// explotacion, evita dividir por cero).
  Future<Estrategia?> seleccionarEstrategia() async {
    final activas = await (_db.select(_db.estrategias)
          ..where((e) => e.activo.equals(true)))
        .get();
    if (activas.isEmpty) return null;

    final intentos = <String, int>{};
    final exitos = <String, int>{};
    var totalIntentos = 0;

    for (final estrategia in activas) {
      final n = await _contarIntentos(estrategia.codEstrategia);
      intentos[estrategia.codEstrategia] = n;
      exitos[estrategia.codEstrategia] =
          await _contarExitos(estrategia.codEstrategia);
      totalIntentos += n;
    }

    final sinProbar =
        activas.where((e) => intentos[e.codEstrategia] == 0);
    if (sinProbar.isNotEmpty) return sinProbar.first;

    return activas.reduce((mejor, actual) {
      final scoreMejor = _ucb1(
          exitos[mejor.codEstrategia]!, intentos[mejor.codEstrategia]!, totalIntentos);
      final scoreActual = _ucb1(exitos[actual.codEstrategia]!,
          intentos[actual.codEstrategia]!, totalIntentos);
      return scoreActual > scoreMejor ? actual : mejor;
    });
  }

  /// Registra la respuesta del cliente a la oferta de `idProcesoPersuasion`.
  /// Aceptar crea la `venta` (con su `detalleVenta`) que cierra el proceso
  /// de persuasion - rechazar no crea nada: la ausencia de venta con ese
  /// mismo id ES el rechazo (asi lo lee el KPI 2, ver queries.drift).
  Future<void> registrarRespuesta({
    required String idProcesoPersuasion,
    required bool aceptada,
  }) async {
    if (!aceptada) return;

    final interaccion = await (_db.select(_db.interacciones)
          ..where((i) => i.idProcesoPersuasion.equals(idProcesoPersuasion)))
        .getSingle();

    final codLoteProducto = interaccion.codLoteProducto;
    if (codLoteProducto == null) {
      throw StateError(
          'La interaccion $idProcesoPersuasion no tiene producto asociado.');
    }
    final producto = await (_db.select(_db.productos)
          ..where((p) => p.codLoteProducto.equals(codLoteProducto)))
        .getSingle();

    final ventaId = await _db.into(_db.ventas).insert(VentasCompanion.insert(
          canal: interaccion.canal,
          correlativo: await _siguienteCorrelativoVenta(interaccion.canal),
          idProcesoPersuasion: idProcesoPersuasion,
          codCliente: interaccion.codCliente,
          codEstrategia: Value(interaccion.codEstrategia),
          tipoTransaccion: interaccion.tipoTransaccion,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));

    await _db.into(_db.detalleVenta).insert(DetalleVentaCompanion.insert(
          ventaId: ventaId,
          codLoteProducto: producto.codLoteProducto,
          cantidad: 1,
          precioUnitarioCentavos: producto.precioUnitarioCentavos, // snapshot
        ));
  }

  /// score = exitos/intentos + sqrt(2 * ln(N) / intentos)
  double _ucb1(int exitos, int intentos, int totalIntentos) {
    return (exitos / intentos) +
        math.sqrt(2 * math.log(totalIntentos) / intentos);
  }

  Future<int> _contarIntentos(String codEstrategia) async {
    final total = _db.interacciones.id.count();
    final fila = await (_db.selectOnly(_db.interacciones)
          ..addColumns([total])
          ..where(_db.interacciones.codEstrategia.equals(codEstrategia)))
        .getSingle();
    return fila.read(total) ?? 0;
  }

  Future<int> _contarExitos(String codEstrategia) async {
    final total = _db.ventas.id.count();
    final fila = await (_db.selectOnly(_db.ventas)
          ..addColumns([total])
          ..where(_db.ventas.codEstrategia.equals(codEstrategia)))
        .getSingle();
    return fila.read(total) ?? 0;
  }

  Future<int> _siguienteCorrelativoVenta(String canal) async {
    final ultima = await (_db.select(_db.ventas)
          ..where((v) => v.canal.equals(canal))
          ..orderBy([(v) => OrderingTerm.desc(v.correlativo)])
          ..limit(1))
        .getSingleOrNull();
    return (ultima?.correlativo ?? 0) + 1;
  }
}
