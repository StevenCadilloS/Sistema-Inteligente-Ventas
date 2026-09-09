import 'dart:math' as math;

import '../../data/modelos/modelos.dart';
import '../../data/repositories/tienda_repository.dart';

/// Aprendizaje Multi-Armed Bandit (UCB1) sobre `estrategias`
/// (docs/PLAN_ELVIS.md fase 06).
///
/// exitos/intentos se recalculan EN VIVO desde `ventas`/`interacciones` en
/// cada seleccion (Estrategia A "recalculado al vuelo" de
/// docs/MODELO_ANDROID_ROOM.md §2.3) - deliberadamente NO se leen ni se
/// escriben las columnas derivadas `estrategias.ventas_generadas` /
/// `total_veces_aplicada`, que quedan exclusivas del cierre diario. Mezclar
/// ambas fuentes para el mismo dato haria que se pisen entre si
/// (docs/PLAN_ELVIS.md seccion 6).
///
/// Con la base compartida el aprendizaje deja de ser por dispositivo: los
/// intentos y cierres de todos los usuarios alimentan el mismo contador, asi
/// que el UCB1 converge con la experiencia de la tienda entera y no con la de
/// un celular. Es la consecuencia que mas cambia el comportamiento observable
/// del sistema.
class BanditOptimizer {
  BanditOptimizer(this._repo);

  final TiendaRepository _repo;

  /// Elige la estrategia activa con mejor score UCB1. Una estrategia que
  /// nunca se aplico se prioriza sobre el score (exploracion antes que
  /// explotacion, evita dividir por cero).
  Future<Estrategia?> seleccionarEstrategia() async {
    // Una sola consulta trae las estrategias con sus intentos y exitos ya
    // agregados por el servidor. Antes eran tres (estrategias + dos GROUP BY);
    // sobre una base remota, cada una era un viaje de red dentro del camino
    // critico de cada oferta.
    final activas = await _repo.estrategiasActivas();
    if (activas.isEmpty) return null;

    final totalIntentos = activas.fold<int>(0, (suma, e) => suma + e.intentos);

    final sinProbar = activas.where((e) => e.intentos == 0);
    if (sinProbar.isNotEmpty) return sinProbar.first;

    return activas.reduce(
      (mejor, actual) => _ucb1(actual, totalIntentos) > _ucb1(mejor, totalIntentos)
          ? actual
          : mejor,
    );
  }

  /// Registra la respuesta del cliente a la oferta de `idProcesoPersuasion`.
  /// Aceptar crea la `venta` (con su `detalleVenta`) que cierra el proceso
  /// de persuasion - rechazar no crea nada: la ausencia de venta con ese
  /// mismo id ES el rechazo (asi lo lee el KPI 2).
  ///
  /// [precioFinalCentavos] es el precio que realmente se le mostro al cliente
  /// (con el descuento de la oferta ya aplicado). Se congela tal cual en
  /// `detalle_venta`: la venta debe registrar lo que se ofrecio, no el precio
  /// de lista. Si se omite, el servidor usa el precio vigente del producto.
  ///
  /// Lanza [SinStockException] si otro cliente se llevo la ultima unidad
  /// mientras este decidia.
  Future<void> registrarRespuesta({
    required String idProcesoPersuasion,
    required bool aceptada,
    int? precioFinalCentavos,
  }) async {
    if (!aceptada) return;

    await _repo.registrarVenta(
      idProcesoPersuasion: idProcesoPersuasion,
      precioFinalCentavos: precioFinalCentavos,
    );
  }

  /// score = exitos/intentos + sqrt(2 * ln(N) / intentos)
  double _ucb1(Estrategia estrategia, int totalIntentos) {
    return (estrategia.exitos / estrategia.intentos) +
        math.sqrt(2 * math.log(totalIntentos) / estrategia.intentos);
  }
}
