import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/database/app_database.dart';
import 'package:tienda_adaptativa/decision/adaptation_engine.dart';

/// Prueba de humo de la fase 05 (docs/PLAN_ELVIS.md - el rubro de 8 puntos
/// del taller): valida que cada emocion produce una oferta distinta y que
/// cada decision queda registrada en `interacciones`.
void main() {
  late AppDatabase db;
  late AdaptationEngine engine;
  const codCliente = 'C0000001';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').getSingle(); // dispara onCreate/seed
    engine = AdaptationEngine(db);

    await db.into(db.clientes).insert(ClientesCompanion.insert(
          codCliente: codCliente,
          nombre: 'Carlos',
          apellido: 'Ramirez',
          fechaIngreso: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        ));

    await db.into(db.tiposProducto).insert(
        TiposProductoCompanion.insert(
            tipoProducto: 'T00001', nombreTipoProducto: 'Audio'));
    await db.into(db.tiposProducto).insert(
        TiposProductoCompanion.insert(
            tipoProducto: 'T00002', nombreTipoProducto: 'Accesorios'));

    await db.batch((b) {
      b.insertAll(db.productos, [
        ProductosCompanion.insert(
          codLoteProducto: 'P0000001',
          nombreProducto: 'Audifonos Basicos',
          tipoProducto: const Value('T00001'),
          precioUnitarioCentavos: 5000, // el mas economico
          fechaCreacionStock: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        ),
        ProductosCompanion.insert(
          codLoteProducto: 'P0000002',
          nombreProducto: 'Audifonos Premium',
          tipoProducto: const Value('T00001'),
          precioUnitarioCentavos: 25000, // el mas caro
          fechaCreacionStock: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        ),
        ProductosCompanion.insert(
          codLoteProducto: 'P0000003',
          nombreProducto: 'Mouse Gamer',
          tipoProducto: const Value('T00002'), // otra categoria
          precioUnitarioCentavos: 8000,
          fechaCreacionStock: DateTime(2026, 1, 1).millisecondsSinceEpoch,
          totalVecesMostrado: const Value(50), // el mas mostrado
        ),
      ]);
    });

    await db.into(db.estrategias).insert(EstrategiasCompanion.insert(
          codEstrategia: 'E0000001',
          nombreEstrategia: 'Sustituto economico',
        ));
  });

  tearDown(() => db.close());

  test('triste -> el producto mas economico', () async {
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      codGesto: 'G0000001', // triste
      nivelDeInteres: 60,
    );
    expect(oferta.producto.codLoteProducto, 'P0000001');
  });

  test('feliz -> el producto mas caro (premium)', () async {
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      codGesto: 'G0000002', // feliz
      nivelDeInteres: 90,
    );
    expect(oferta.producto.codLoteProducto, 'P0000002');
  });

  test('neutral -> el producto mas mostrado (estandar)', () async {
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      codGesto: 'G0000004', // neutral
      nivelDeInteres: 50,
    );
    expect(oferta.producto.codLoteProducto, 'P0000003');
  });

  test('enojo -> cambia de categoria respecto al ultimo producto mostrado',
      () async {
    // Primero se le muestra un producto de la categoria Audio (feliz).
    await engine.decidirOferta(
      codCliente: codCliente,
      codGesto: 'G0000002',
      nivelDeInteres: 80,
    );

    // Ahora se enoja: debe saltar a la categoria Accesorios (P0000003).
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      codGesto: 'G0000005', // enojo
      nivelDeInteres: 70,
    );
    expect(oferta.producto.tipoProducto, 'T00002');
  });

  test('cada decision registra una fila en interacciones con FK completas',
      () async {
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      codGesto: 'G0000003', // sorpresa
      nivelDeInteres: 75,
    );

    final fila = await (db.select(db.interacciones)
          ..where((i) =>
              i.idProcesoPersuasion.equals(oferta.idProcesoPersuasion)))
        .getSingle();

    expect(fila.codCliente, codCliente);
    expect(fila.codGesto, 'G0000003');
    expect(fila.codLoteProducto, oferta.producto.codLoteProducto);
    expect(fila.codEstrategia, 'E0000001');
    expect(fila.nivelDeInteres, 75);
  });

  test('la regla eliminatoria: la oferta cambia sola sin intervencion manual',
      () async {
    final triste = await engine.decidirOferta(
      codCliente: codCliente,
      codGesto: 'G0000001',
      nivelDeInteres: 60,
    );
    final feliz = await engine.decidirOferta(
      codCliente: codCliente,
      codGesto: 'G0000002',
      nivelDeInteres: 60,
    );

    // Mismo cliente, mismo nivelDeInteres, unico input distinto: el gesto.
    expect(triste.producto.codLoteProducto,
        isNot(feliz.producto.codLoteProducto));
  });
}
