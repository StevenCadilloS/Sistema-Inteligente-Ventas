import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/database/app_database.dart';
import 'package:tienda_adaptativa/decision/learning/bandit_optimizer.dart';

/// Prueba de humo de la fase 06 (docs/PLAN_ELVIS.md): UCB1 prioriza
/// estrategias no probadas, y luego la que mejor conversion tiene;
/// aceptar/rechazar crea o no crea la venta que cierra el proceso.
void main() {
  late AppDatabase db;
  late BanditOptimizer bandit;
  const codCliente = 'C0000001';
  var correlativo = 0;

  Future<void> registrarInteraccion({
    required String idProcesoPersuasion,
    required String codEstrategia,
    String codLoteProducto = 'P0000001',
  }) async {
    await db.into(db.interacciones).insert(InteraccionesCompanion.insert(
          canal: 'A',
          correlativo: ++correlativo,
          idProcesoPersuasion: idProcesoPersuasion,
          codCliente: codCliente,
          codEstrategia: Value(codEstrategia),
          codLoteProducto: Value(codLoteProducto),
          tipoTransaccion: 'TRX0001',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          nivelDeInteres: 70,
        ));
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').getSingle(); // dispara onCreate/seed
    bandit = BanditOptimizer(db);

    await db.into(db.clientes).insert(ClientesCompanion.insert(
          codCliente: codCliente,
          nombre: 'Carlos',
          apellido: 'Ramirez',
          fechaIngreso: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        ));
    await db.into(db.productos).insert(ProductosCompanion.insert(
          codLoteProducto: 'P0000001',
          nombreProducto: 'Audifonos',
          precioUnitarioCentavos: 15000,
          fechaCreacionStock: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        ));
    await db.batch((b) {
      b.insertAll(db.estrategias, [
        EstrategiasCompanion.insert(
            codEstrategia: 'E0000001', nombreEstrategia: 'Sustituto'),
        EstrategiasCompanion.insert(
            codEstrategia: 'E0000002', nombreEstrategia: 'Descuento'),
      ]);
    });
  });

  tearDown(() => db.close());

  test('prioriza una estrategia nunca aplicada sobre una ya probada',
      () async {
    // E0000001 ya se aplico una vez; E0000002 nunca.
    await registrarInteraccion(
        idProcesoPersuasion: 'PP00000001', codEstrategia: 'E0000001');

    final elegida = await bandit.seleccionarEstrategia();

    expect(elegida?.codEstrategia, 'E0000002');
  });

  test(
      'una vez que todas se probaron, favorece la de mejor tasa de conversion',
      () async {
    // E0000001: 1 intento, 1 exito (100%).
    await registrarInteraccion(
        idProcesoPersuasion: 'PP00000001', codEstrategia: 'E0000001');
    await bandit.registrarRespuesta(
        idProcesoPersuasion: 'PP00000001', aceptada: true);

    // E0000002: 3 intentos, 0 exitos (0%).
    for (final id in ['PP00000002', 'PP00000003', 'PP00000004']) {
      await registrarInteraccion(idProcesoPersuasion: id, codEstrategia: 'E0000002');
      await bandit.registrarRespuesta(idProcesoPersuasion: id, aceptada: false);
    }

    final elegida = await bandit.seleccionarEstrategia();

    expect(elegida?.codEstrategia, 'E0000001');
  });

  test('registrarRespuesta(aceptada: true) crea venta y detalleVenta',
      () async {
    await registrarInteraccion(
        idProcesoPersuasion: 'PP00000001', codEstrategia: 'E0000001');

    await bandit.registrarRespuesta(
        idProcesoPersuasion: 'PP00000001', aceptada: true);

    final venta = await (db.select(db.ventas)
          ..where((v) => v.idProcesoPersuasion.equals('PP00000001')))
        .getSingle();
    expect(venta.codCliente, codCliente);
    expect(venta.codEstrategia, 'E0000001');

    final detalle = await (db.select(db.detalleVenta)
          ..where((d) => d.ventaId.equals(venta.id)))
        .getSingle();
    expect(detalle.codLoteProducto, 'P0000001');
    expect(detalle.precioUnitarioCentavos, 15000); // snapshot del precio
  });

  test('registrarRespuesta(aceptada: false) NO crea venta (asi se infiere el rechazo)',
      () async {
    await registrarInteraccion(
        idProcesoPersuasion: 'PP00000001', codEstrategia: 'E0000001');

    await bandit.registrarRespuesta(
        idProcesoPersuasion: 'PP00000001', aceptada: false);

    final ventas = await (db.select(db.ventas)
          ..where((v) => v.idProcesoPersuasion.equals('PP00000001')))
        .get();
    expect(ventas, isEmpty);
  });

  test('sin estrategias activas devuelve null en vez de fallar', () async {
    await db.customUpdate('UPDATE estrategias SET activo = 0');

    final elegida = await bandit.seleccionarEstrategia();

    expect(elegida, isNull);
  });
}
