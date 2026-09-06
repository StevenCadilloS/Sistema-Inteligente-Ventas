import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/database/app_database.dart';

/// Fase 03 (docs/PLAN_ELVIS.md): verificacion contra el papel. Carga el
/// Primer y Segundo Caso reales de docs/TABLAS.docx. Su contenido esta en
/// 21 imagenes incrustadas, no en texto plano (ver docs/ESQUEMA_CORREGIDO.md
/// "Metodo"), asi que se extrajeron a mano del .docx (word/media/*.png).
///
/// Cada caso es un proceso de persuasion completo: varias filas de
/// `interacciones` con el mismo id_proceso_persuasion y distinto
/// correlativo (se le muestran uno o mas productos/estrategias al cliente
/// en la misma sesion), que termina en una `venta`.
///
/// Alcance de esta verificacion: la vista de la consulta critica y los 4
/// KPIs, que SI se pueden recalcular con las filas dadas. Los contadores
/// derivados (cant_lecturas, monto_total, total_vendidos...) NO se
/// verifican aqui: sus valores "antes" dependen de cientos de filas
/// historicas que las imagenes omiten con "...", asi que no hay forma de
/// reconstruirlos desde cero. (Ademas, comparando las capturas "antes" y
/// "despues" de MAESTRA PRODUCTOS, el propio documento tiene deltas
/// inconsistentes entre total_disponible y total_vendidos para P0000022 -
/// una errata mas del material fuente, en la linea de G1-G9/N1-N4/D1-D3.)
///
/// Correcciones aplicadas a los datos crudos de las imagenes:
/// - `cod_cliente` en MAESTRA CLIENTES aparece como C00002/C00023 (5
///   digitos) pero todas las FK (interacciones, ventas) usan
///   C0000002/C0000023 (7 digitos) - se usa el formato de 7 digitos.
/// - El Segundo Caso repite correlativo 0003 dos veces (17:22:11 y
///   17:22:13) con distinto tipo_transaccion - viola UNIQUE(canal,
///   correlativo). Se renumera la segunda ocurrencia (la que coincide en
///   hora con la venta) como 0004.
/// - `precio_unitario_centavos` en detalle_venta no tiene equivalente en
///   los datos originales (es exactamente el hallazgo G5: "no hay precio
///   en ninguna tabla"). Se usa un valor nominal solo para satisfacer la
///   columna NOT NULL de la correccion C5; no viene del documento.
/// - `cod_gesto` G0000008 (Segundo Caso, correlativo 0001) no esta entre
///   las 5 emociones basicas que siembra AppDatabase - se agrega aqui como
///   catalogo adicional. Senal real para Juan: los datos historicos usan
///   mas gestos que las 5 clases FER-2013 del clasificador actual.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').getSingle(); // dispara onCreate/seed
    await _sembrarCatalogosComunes(db);
  });

  tearDown(() => db.close());

  test('Primer Caso: carga completa y la vista de consulta critica cuadra',
      () async {
    await _cargarPrimerCaso(db);

    final vista = await db.select(db.vCierresPorTipoProducto).get();
    expect(vista, hasLength(1));
    expect(vista.single.codCliente, 'C0000002');
    expect(vista.single.codLoteProducto, 'P0000005');
    expect(vista.single.cantidad, 1);
  });

  test('Segundo Caso: carga completa y la vista de consulta critica cuadra',
      () async {
    await _cargarSegundoCaso(db);

    final vista = await db.select(db.vCierresPorTipoProducto).get();
    expect(vista, hasLength(1));
    expect(vista.single.codCliente, 'C0000023');
    expect(vista.single.codLoteProducto, 'P0000022');
  });

  test('KPI1: ambos casos cierran al 100% en su propio mes', () async {
    await _cargarPrimerCaso(db); // junio 2025
    await _cargarSegundoCaso(db); // mayo 2025

    final porMes = {
      for (final fila in await db.kpi1CierreVentasPorMes().get())
        fila.mes: fila.porcentaje,
    };

    expect(porMes['2025-06'], 100.0);
    expect(porMes['2025-05'], 100.0);
  });

  test(
      'KPI2: 1 de los 2 procesos mostro un solo producto (Primer Caso: '
      'solo P0000005; Segundo Caso: P0000024 y P0000022)', () async {
    await _cargarPrimerCaso(db);
    await _cargarSegundoCaso(db);

    final kpi2 = await db.kpi2VentasSinProductoAlternativo().getSingle();
    expect(kpi2, 50.0);
  });

  test('KPI4: sin filtrar nada, suma las 2 ventas de ambos casos', () async {
    await _cargarPrimerCaso(db);
    await _cargarSegundoCaso(db);

    final kpi4 = await db.kpi4VentasPorDiaSemana().get();
    expect(kpi4.fold<int>(0, (suma, fila) => suma + fila.ventas), 2);
  });
}

/// TRX0002-06 y el gesto G0000008 no vienen en la semilla por defecto de
/// AppDatabase (esa cubre solo lo minimo para el pipeline actual); las
/// dos estrategias se comparten entre ambos casos.
Future<void> _sembrarCatalogosComunes(AppDatabase db) async {
  await db.batch((b) {
    b.insertAll(db.tiposTransaccion, [
      TiposTransaccionCompanion.insert(
          codTransaccion: 'TRX0003', tipoTrx: 'proceso_online_paso_1'),
      TiposTransaccionCompanion.insert(
          codTransaccion: 'TRX0004', tipoTrx: 'proceso_online_paso_2'),
      TiposTransaccionCompanion.insert(
          codTransaccion: 'TRX0005', tipoTrx: 'proceso_online_paso_3'),
      TiposTransaccionCompanion.insert(
          codTransaccion: 'TRX0006', tipoTrx: 'proceso_online_cierre'),
    ]);
    b.insertAll(db.gestos, [
      GestosCompanion.insert(
          codGesto: 'G0000008',
          nombreGesto: 'sin_clasificar', // fuera de las 5 emociones basicas
          descripcion:
              const Value('Gesto de TABLAS.docx sin mapeo en el clasificador actual')),
    ]);
    b.insertAll(db.estrategias, [
      EstrategiasCompanion.insert(
          codEstrategia: 'E0000001', nombreEstrategia: 'Sustituto economico'),
      EstrategiasCompanion.insert(
          codEstrategia: 'E0000002',
          nombreEstrategia: 'Fomento de compra impulsiva'),
    ]);
  });
}

/// docs/TABLAS.docx, Primer Caso (imagenes image18/image2/image3 -
/// interacciones, image16 - venta, image21 - detalle venta).
Future<void> _cargarPrimerCaso(AppDatabase db) async {
  await db.into(db.clientes).insert(ClientesCompanion.insert(
        codCliente: 'C0000002',
        nombre: 'Juan',
        apellido: '',
        fechaIngreso: DateTime(2025, 3, 2).millisecondsSinceEpoch,
      ));
  await db.into(db.productos).insert(ProductosCompanion.insert(
        codLoteProducto: 'P0000005',
        nombreProducto: 'Camiseta basica',
        precioUnitarioCentavos: 2500, // no viene en el documento (G5)
        fechaCreacionStock: DateTime(2023, 5, 2).millisecondsSinceEpoch,
      ));

  await db.batch((b) {
    b.insertAll(db.interacciones, [
      InteraccionesCompanion.insert(
        canal: 'W',
        correlativo: 1,
        idProcesoPersuasion: 'I0000001',
        codCliente: 'C0000002',
        codEstrategia: const Value(null), // 00000000 en el original (G9/C11)
        codGesto: const Value('G0000004'),
        codLoteProducto: const Value('P0000005'),
        tipoTransaccion: 'TRX0003',
        timestamp: DateTime(2025, 6, 4, 9, 12, 11).millisecondsSinceEpoch,
        nivelDeInteres: 70,
      ),
      InteraccionesCompanion.insert(
        canal: 'W',
        correlativo: 2,
        idProcesoPersuasion: 'I0000001',
        codCliente: 'C0000002',
        codEstrategia: const Value('E0000002'),
        codGesto: const Value('G0000004'),
        codLoteProducto: const Value('P0000005'),
        tipoTransaccion: 'TRX0004',
        timestamp: DateTime(2025, 6, 4, 9, 13, 12).millisecondsSinceEpoch,
        nivelDeInteres: 90,
      ),
      InteraccionesCompanion.insert(
        canal: 'W',
        correlativo: 3,
        idProcesoPersuasion: 'I0000001',
        codCliente: 'C0000002',
        codEstrategia: const Value('E0000002'),
        codGesto: const Value(null), // "0" en el original
        codLoteProducto: const Value('P0000005'),
        tipoTransaccion: 'TRX0005',
        timestamp: DateTime(2025, 6, 5, 9, 13, 47).millisecondsSinceEpoch,
        nivelDeInteres: 90,
      ),
    ]);
  });

  final ventaId = await db.into(db.ventas).insert(VentasCompanion.insert(
        canal: 'W',
        correlativo: 1,
        idProcesoPersuasion: 'I0000001',
        codCliente: 'C0000002',
        codEstrategia: const Value('E0000002'),
        tipoTransaccion: 'TRX0006',
        timestamp: DateTime(2025, 6, 5, 9, 13, 47).millisecondsSinceEpoch,
      ));
  await db.into(db.detalleVenta).insert(DetalleVentaCompanion.insert(
        ventaId: ventaId,
        codLoteProducto: 'P0000005',
        cantidad: 1,
        precioUnitarioCentavos: 2500,
      ));
}

/// docs/TABLAS.docx, Segundo Caso (imagenes image17/image9/image11 -
/// interacciones, image7 - venta, image6 - detalle venta).
Future<void> _cargarSegundoCaso(AppDatabase db) async {
  await db.into(db.clientes).insert(ClientesCompanion.insert(
        codCliente: 'C0000023',
        nombre: 'Sebastian',
        apellido: '',
        fechaIngreso: DateTime(2025, 3, 2).millisecondsSinceEpoch,
      ));
  await db.batch((b) {
    b.insertAll(db.productos, [
      ProductosCompanion.insert(
        codLoteProducto: 'P0000022',
        nombreProducto: 'Pantalon gris',
        precioUnitarioCentavos: 4500, // no viene en el documento (G5)
        fechaCreacionStock: DateTime(2025, 2, 2).millisecondsSinceEpoch,
      ),
      ProductosCompanion.insert(
        codLoteProducto: 'P0000024',
        nombreProducto: 'Jean clasico',
        precioUnitarioCentavos: 6000,
        fechaCreacionStock: DateTime(2025, 7, 1).millisecondsSinceEpoch,
      ),
    ]);
  });

  await db.batch((b) {
    b.insertAll(db.interacciones, [
      InteraccionesCompanion.insert(
        canal: 'A',
        correlativo: 1,
        idProcesoPersuasion: 'I0000013',
        codCliente: 'C0000023',
        codEstrategia: const Value(null), // 00000000 en el original
        codGesto: const Value('G0000008'),
        codLoteProducto: const Value('P0000024'),
        tipoTransaccion: 'TRX0003',
        timestamp: DateTime(2025, 5, 26, 17, 20, 11).millisecondsSinceEpoch,
        nivelDeInteres: 30,
      ),
      InteraccionesCompanion.insert(
        canal: 'A',
        correlativo: 2,
        idProcesoPersuasion: 'I0000013',
        codCliente: 'C0000023',
        codEstrategia: const Value('E0000001'),
        codGesto: const Value('G0000004'),
        codLoteProducto: const Value('P0000022'), // cambia de producto
        tipoTransaccion: 'TRX0004',
        timestamp: DateTime(2025, 5, 26, 17, 21, 11).millisecondsSinceEpoch,
        nivelDeInteres: 80,
      ),
      InteraccionesCompanion.insert(
        canal: 'A',
        correlativo: 3,
        idProcesoPersuasion: 'I0000013',
        codCliente: 'C0000023',
        codEstrategia: const Value('E0000002'),
        codGesto: const Value('G0000004'),
        codLoteProducto: const Value('P0000022'),
        tipoTransaccion: 'TRX0004',
        timestamp: DateTime(2025, 5, 26, 17, 22, 11).millisecondsSinceEpoch,
        nivelDeInteres: 90,
      ),
      InteraccionesCompanion.insert(
        canal: 'A',
        correlativo: 4, // renumerado: el original repite 0003 (ver arriba)
        idProcesoPersuasion: 'I0000013',
        codCliente: 'C0000023',
        codEstrategia: const Value('E0000002'),
        codGesto: const Value('G0000004'),
        codLoteProducto: const Value('P0000022'),
        tipoTransaccion: 'TRX0005',
        timestamp: DateTime(2025, 5, 26, 17, 22, 13).millisecondsSinceEpoch,
        nivelDeInteres: 90,
      ),
    ]);
  });

  final ventaId = await db.into(db.ventas).insert(VentasCompanion.insert(
        canal: 'A',
        correlativo: 1,
        idProcesoPersuasion: 'I0000013',
        codCliente: 'C0000023',
        codEstrategia: const Value('E0000002'),
        tipoTransaccion: 'TRX0006',
        timestamp: DateTime(2025, 5, 26, 17, 22, 13).millisecondsSinceEpoch,
      ));
  await db.into(db.detalleVenta).insert(DetalleVentaCompanion.insert(
        ventaId: ventaId,
        codLoteProducto: 'P0000022',
        cantidad: 1,
        precioUnitarioCentavos: 4500,
      ));
}
