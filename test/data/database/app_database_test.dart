import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/database/app_database.dart';

/// Prueba de humo del esquema (Fase 02 de docs/PLAN_ELVIS.md): abre una
/// base en memoria, siembra los catalogos, registra una interaccion + una
/// venta + su detalle (un ciclo completo de persuasion), y valida que las
/// FK, la vista de la consulta critica y los 4 KPIs funcionan de punta a
/// punta - no solo que el esquema compila.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Fuerza la apertura de la conexion, lo que dispara
    // MigrationStrategy.onCreate (createAll + seedCatalogos). Sembrar de
    // nuevo aqui duplicaria las filas de los catalogos.
    await db.customSelect('SELECT 1').getSingle();
  });

  tearDown(() => db.close());

  test('siembra los 4 catalogos antes que cualquier bitacora', () async {
    expect(await db.select(db.tiposCliente).get(), hasLength(3));
    expect(await db.select(db.gestos).get(), hasLength(5));
    expect(await db.select(db.tiposTransaccion).get(), hasLength(1));
  });

  test('ciclo completo: interaccion -> venta -> detalle, con FK activas',
      () async {
    await db
        .into(db.tiposProducto)
        .insert(TiposProductoCompanion.insert(
            tipoProducto: 'T00001', nombreTipoProducto: 'Audifonos'));
    await db.into(db.productos).insert(ProductosCompanion.insert(
          codLoteProducto: 'P0000001',
          nombreProducto: 'Audifonos Bluetooth',
          tipoProducto: const Value('T00001'),
          precioUnitarioCentavos: 15000,
          fechaCreacionStock: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        ));
    await db.into(db.clientes).insert(ClientesCompanion.insert(
          codCliente: 'C0000001',
          nombre: 'Carlos',
          apellido: 'Ramirez',
          fechaIngreso: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        ));
    await db.into(db.estrategias).insert(EstrategiasCompanion.insert(
          codEstrategia: 'E0000001',
          nombreEstrategia: 'Sustituto economico',
        ));

    final timestamp = DateTime(2026, 3, 5, 10, 30).millisecondsSinceEpoch;

    // Fase 1-2 (contexto/procesamiento, ya en Kotlin): produce un gesto
    // "triste" con nivel_de_interes 80. Fase 3 (decision, este esquema):
    // registra el intento de persuasion.
    await db.into(db.interacciones).insert(InteraccionesCompanion.insert(
          canal: 'A',
          correlativo: 1,
          idProcesoPersuasion: 'PP00000001', // C1
          codCliente: 'C0000001',
          codEstrategia: const Value('E0000001'),
          codGesto: const Value('G0000001'), // triste
          codLoteProducto: const Value('P0000001'),
          tipoTransaccion: 'TRX0001',
          timestamp: timestamp,
          nivelDeInteres: 80,
        ));

    // El cliente acepta la oferta -> se registra el cierre con el MISMO
    // idProcesoPersuasion (esto es exactamente lo que G1/C1 desbloquea).
    final ventaId = await db.into(db.ventas).insert(VentasCompanion.insert(
          canal: 'A',
          correlativo: 1,
          idProcesoPersuasion: 'PP00000001',
          codCliente: 'C0000001',
          codEstrategia: const Value('E0000001'),
          tipoTransaccion: 'TRX0001',
          timestamp: timestamp,
        ));
    await db.into(db.detalleVenta).insert(DetalleVentaCompanion.insert(
          ventaId: ventaId,
          codLoteProducto: 'P0000001',
          cantidad: 1,
          precioUnitarioCentavos: 15000,
        ));

    // La vista de la consulta critica (reemplaza el grupo repetitivo G8)
    // debe devolver la fila venta-producto ya desnormalizada.
    final filasVista = await db.select(db.vCierresPorTipoProducto).get();
    expect(filasVista, hasLength(1));
    expect(filasVista.single.codCliente, 'C0000001');
    expect(filasVista.single.importeCentavos, 15000);

    // KPI 1: % de cierre de ventas por mes - 1 intento, 1 cierre -> 100%.
    final kpi1 = await db.kpi1CierreVentasPorMes().get();
    expect(kpi1, hasLength(1));
    expect(kpi1.single.porcentaje, 100.0);

    // KPI 2: % de ventas sin producto alternativo - un solo producto
    // mostrado en el proceso que cerro -> 100%.
    final kpi2 = await db.kpi2VentasSinProductoAlternativo().getSingle();
    expect(kpi2, 100.0);

    // KPI 3: efectividad de la estrategia para el proceso registrado.
    final kpi3 = await db.kpi3EfectividadEstrategiaPorTipoCliente().get();
    expect(kpi3, hasLength(1));
    expect(kpi3.single.efectividad, 100.0);

    // KPI 4: distribucion de ventas por dia de semana (D2: Tercer KPI.png).
    final kpi4 = await db.kpi4VentasPorDiaSemana().get();
    expect(kpi4.fold<int>(0, (sum, row) => sum + row.ventas), 1);
  });

  test('batch: cierresVenta y totalVendidos coinciden tras una venta',
      () async {
    await db.into(db.productos).insert(ProductosCompanion.insert(
          codLoteProducto: 'P0000002',
          nombreProducto: 'Mouse Gamer',
          precioUnitarioCentavos: 8000,
          fechaCreacionStock: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        ));
    await db.into(db.clientes).insert(ClientesCompanion.insert(
          codCliente: 'C0000002',
          nombre: 'Ana',
          apellido: 'Torres',
          fechaIngreso: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        ));
    final ventaId = await db.into(db.ventas).insert(VentasCompanion.insert(
          canal: 'A',
          correlativo: 1,
          idProcesoPersuasion: 'PP00000002',
          codCliente: 'C0000002',
          tipoTransaccion: 'TRX0001',
          timestamp: DateTime(2026, 3, 6).millisecondsSinceEpoch,
        ));
    await db.into(db.detalleVenta).insert(DetalleVentaCompanion.insert(
          ventaId: ventaId,
          codLoteProducto: 'P0000002',
          cantidad: 2,
          precioUnitarioCentavos: 8000,
        ));

    // D3: cierresVenta se mantiene, mismo COUNT que totalVendidos.
    await db.batchActualizarCierresVenta();
    await db.batchActualizarTotalVendidos();
    await db.batchActualizarTotalesCliente();

    final producto = await (db.select(db.productos)
          ..where((p) => p.codLoteProducto.equals('P0000002')))
        .getSingle();
    expect(producto.cierresVenta, 1);
    expect(producto.totalVendidos, 1);

    final cliente = await (db.select(db.clientes)
          ..where((c) => c.codCliente.equals('C0000002')))
        .getSingle();
    expect(cliente.montoTotalCentavos, 16000); // 2 x 8000
  });
}
