import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/batch/batch_runner.dart';
import 'package:tienda_adaptativa/data/database/app_database.dart';

/// Fase 07 (docs/PLAN_ELVIS.md): el cierre diario actualiza los 6
/// contadores derivados en una sola pasada, a partir de 2 interacciones
/// (mismo cliente/estrategia, distinto proceso) y 1 venta que cierra una
/// de ellas.
void main() {
  late AppDatabase db;
  late BatchRunner batch;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').getSingle(); // dispara onCreate/seed
    batch = BatchRunner(db);

    await db.into(db.clientes).insert(ClientesCompanion.insert(
          codCliente: 'C0000001',
          nombre: 'Carlos',
          apellido: 'Ramirez',
          fechaIngreso: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        ));
    await db.into(db.productos).insert(ProductosCompanion.insert(
          codLoteProducto: 'P0000001',
          nombreProducto: 'Audifonos',
          precioUnitarioCentavos: 1000,
          fechaCreacionStock: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        ));
    await db.into(db.estrategias).insert(EstrategiasCompanion.insert(
          codEstrategia: 'E0000001',
          nombreEstrategia: 'Sustituto economico',
        ));

    // Dos procesos de persuasion distintos para el mismo cliente/estrategia:
    // uno cierra en venta, el otro no.
    await db.batch((b) {
      b.insertAll(db.interacciones, [
        InteraccionesCompanion.insert(
          canal: 'A',
          correlativo: 1,
          idProcesoPersuasion: 'PP00000001',
          codCliente: 'C0000001',
          codEstrategia: const Value('E0000001'),
          codLoteProducto: const Value('P0000001'),
          tipoTransaccion: 'TRX0001',
          timestamp: DateTime(2026, 3, 1).millisecondsSinceEpoch,
          nivelDeInteres: 80,
        ),
        InteraccionesCompanion.insert(
          canal: 'A',
          correlativo: 2,
          idProcesoPersuasion: 'PP00000002',
          codCliente: 'C0000001',
          codEstrategia: const Value('E0000001'),
          codLoteProducto: const Value('P0000001'),
          tipoTransaccion: 'TRX0001',
          timestamp: DateTime(2026, 3, 2).millisecondsSinceEpoch,
          nivelDeInteres: 60,
        ),
      ]);
    });

    final ventaId = await db.into(db.ventas).insert(VentasCompanion.insert(
          canal: 'A',
          correlativo: 1,
          idProcesoPersuasion: 'PP00000001', // solo la primera cierra
          codCliente: 'C0000001',
          codEstrategia: const Value('E0000001'),
          tipoTransaccion: 'TRX0001',
          timestamp: DateTime(2026, 3, 1).millisecondsSinceEpoch,
        ));
    await db.into(db.detalleVenta).insert(DetalleVentaCompanion.insert(
          ventaId: ventaId,
          codLoteProducto: 'P0000001',
          cantidad: 2,
          precioUnitarioCentavos: 1000,
        ));
  });

  tearDown(() => db.close());

  test('ejecutarCierreDiario actualiza estrategias, clientes y productos en una pasada',
      () async {
    await batch.ejecutarCierreDiario();

    final estrategia = await (db.select(db.estrategias)
          ..where((e) => e.codEstrategia.equals('E0000001')))
        .getSingle();
    // D1: agrupado por codEstrategia, no por codCliente.
    expect(estrategia.totalVecesAplicada, 2); // 2 interacciones
    expect(estrategia.ventasGeneradas, 1); // 1 de las 2 cerro

    final cliente = await (db.select(db.clientes)
          ..where((c) => c.codCliente.equals('C0000001')))
        .getSingle();
    expect(cliente.cantLecturas, 2); // 2 procesos distintos
    expect(cliente.totalCompras, 1);
    expect(cliente.montoTotalCentavos, 2000); // 2 x 1000
    expect(cliente.ultimaVisita, DateTime(2026, 3, 1).millisecondsSinceEpoch);

    final producto = await (db.select(db.productos)
          ..where((p) => p.codLoteProducto.equals('P0000001')))
        .getSingle();
    expect(producto.cierresVenta, 1); // D3
    expect(producto.totalVendidos, 1);
  });

  test(
      'totalVecesAplicada cuenta procesos distintos, no filas: un proceso '
      'con 2 interacciones para la misma estrategia cuenta como 1',
      () async {
    // PP00000001 ya tiene 1 fila para E0000001 (del setUp). Se agrega una
    // SEGUNDA fila del MISMO proceso para la MISMA estrategia.
    await db.into(db.interacciones).insert(InteraccionesCompanion.insert(
          canal: 'A',
          correlativo: 3,
          idProcesoPersuasion: 'PP00000001', // mismo proceso que ya existia
          codCliente: 'C0000001',
          codEstrategia: const Value('E0000001'),
          codLoteProducto: const Value('P0000001'),
          tipoTransaccion: 'TRX0001',
          timestamp: DateTime(2026, 3, 1, 12).millisecondsSinceEpoch,
          nivelDeInteres: 85,
        ));

    await batch.ejecutarCierreDiario();

    final estrategia = await (db.select(db.estrategias)
          ..where((e) => e.codEstrategia.equals('E0000001')))
        .getSingle();
    // Sigue siendo 2 (PP00000001 + PP00000002), no 3: la fila extra es el
    // MISMO proceso que PP00000001, no un intento nuevo.
    expect(estrategia.totalVecesAplicada, 2);
  });

  test('es idempotente: correrlo dos veces da el mismo resultado', () async {
    await batch.ejecutarCierreDiario();
    await batch.ejecutarCierreDiario();

    final estrategia = await (db.select(db.estrategias)
          ..where((e) => e.codEstrategia.equals('E0000001')))
        .getSingle();
    expect(estrategia.totalVecesAplicada, 2);
    expect(estrategia.ventasGeneradas, 1);
  });
}
