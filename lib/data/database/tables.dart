import 'package:drift/drift.dart';

/// Esquema traducido de docs/MODELO_ANDROID_ROOM.md §3, con las
/// decisiones D1/D3 de docs/ESQUEMA_CORREGIDO.md §5 ya aplicadas:
/// - D1: el contador de procesos de persuasion por cliente se llama
///   `cantLecturas` (no `cantEntradas`).
/// - D3: `cierresVenta` se mantiene en Producto.
///
/// Dinero siempre en centavos (INTEGER), nunca REAL (evita error de
/// redondeo binario en `montoTotalCentavos`). Ver docs/PLAN_ELVIS.md
/// seccion 6 (trampas de la migracion).

// ─────────────── CATALOGOS ───────────────
//
// @DataClassName explicito en todas las tablas: la heuristica de
// singularizacion de drift es en ingles y no adivina bien nombres en
// espanol (p.ej. "TiposCliente" no termina en "s", no se singulariza,
// y colisionaria con la clase Table; "Interacciones" terminaria mal
// singularizada como "Interaccione").

@DataClassName('TipoCliente')
class TiposCliente extends Table {
  TextColumn get codTipoCliente => text()(); // T00001
  TextColumn get nombreTipoCliente => text()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {codTipoCliente};
}

@DataClassName('TipoProducto')
class TiposProducto extends Table {
  TextColumn get tipoProducto => text()(); // T00002 (C6)
  TextColumn get nombreTipoProducto => text()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {tipoProducto};
}

/// C2 — cierra la FK huerfana G2. Aqui entra el mapeo de emociones
/// FER-2013 -> gestos del negocio (ver docs/PLAN_ELVIS.md seccion 4).
@DataClassName('Gesto')
class Gestos extends Table {
  TextColumn get codGesto => text()(); // G0000004
  TextColumn get nombreGesto => text()();
  TextColumn get descripcion => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {codGesto};
}

/// C4 — cierra la FK huerfana G4.
@DataClassName('TipoTransaccion')
class TiposTransaccion extends Table {
  TextColumn get codTransaccion => text()(); // TRX0003
  TextColumn get tipoTrx => text()();
  TextColumn get codProtocolo => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {codTransaccion};
}

// ─────────────── MAESTRAS ───────────────

@DataClassName('Cliente')
@TableIndex(name: 'idx_clientes_tipo', columns: {#tipoCliente})
class Clientes extends Table {
  TextColumn get codCliente => text()(); // C0000002
  TextColumn get nombre => text()(); // C6 - separado de apellido
  TextColumn get apellido => text()();
  TextColumn get tipoCliente =>
      text().nullable().references(TiposCliente, #codTipoCliente)(); // C3
  IntColumn get fechaIngreso => integer()(); // epoch millis
  // -- derivados, mantenidos por el batch (ver queries.drift) --
  IntColumn get cantLecturas => integer().withDefault(const Constant(0))(); // D1
  IntColumn get totalCompras => integer().withDefault(const Constant(0))();
  IntColumn get montoTotalCentavos => integer().withDefault(const Constant(0))();
  IntColumn get ultimaVisita => integer().nullable()(); // epoch millis
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {codCliente};
}

@DataClassName('Producto')
@TableIndex(name: 'idx_productos_tipo', columns: {#tipoProducto})
class Productos extends Table {
  TextColumn get codLoteProducto => text()(); // P0000005
  TextColumn get nombreProducto => text()();
  TextColumn get tipoProducto =>
      text().nullable().references(TiposProducto, #tipoProducto)(); // C6
  IntColumn get precioUnitarioCentavos => integer()(); // C5
  IntColumn get fechaCreacionStock => integer()(); // epoch millis
  IntColumn get totalDisponible => integer().withDefault(const Constant(0))();
  // -- derivados --
  IntColumn get totalVendidos => integer().withDefault(const Constant(0))();
  IntColumn get cierresVenta => integer().withDefault(const Constant(0))(); // D3
  IntColumn get totalVecesMostrado => integer().withDefault(const Constant(0))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {codLoteProducto};
}

@DataClassName('Estrategia')
class Estrategias extends Table {
  TextColumn get codEstrategia => text()(); // E0000002
  TextColumn get nombreEstrategia => text()();
  // NO lleva tipoCliente (G3)
  IntColumn get totalVecesAplicada => integer().withDefault(const Constant(0))(); // derivado
  IntColumn get ventasGeneradas => integer().withDefault(const Constant(0))(); // derivado
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {codEstrategia};
}

// ─────────────── BITACORAS ───────────────

@DataClassName('Interaccion')
@TableIndex(name: 'idx_interacciones_proceso', columns: {#idProcesoPersuasion})
@TableIndex(name: 'idx_interacciones_cliente', columns: {#codCliente})
@TableIndex(name: 'idx_interacciones_estrategia', columns: {#codEstrategia})
@TableIndex(name: 'idx_interacciones_timestamp', columns: {#timestamp})
class Interacciones extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get canal => text()(); // 'W' web, 'A' app
  IntColumn get correlativo => integer()();
  TextColumn get idProcesoPersuasion => text()(); // C1 - une intento <-> cierre
  TextColumn get codCliente => text().references(Clientes, #codCliente)();
  TextColumn get codEstrategia =>
      text().nullable().references(Estrategias, #codEstrategia)(); // C11: nullable, sin centinela
  TextColumn get codGesto => text().nullable().references(Gestos, #codGesto)();
  TextColumn get codLoteProducto =>
      text().nullable().references(Productos, #codLoteProducto)(); // C7: nombre unificado
  TextColumn get tipoTransaccion =>
      text().references(TiposTransaccion, #codTransaccion)();
  IntColumn get timestamp => integer()(); // epoch millis - fecha + hora en un solo campo
  IntColumn get nivelDeInteres => integer()(); // 0..100, confianza del clasificador

  // Sin @override de primaryKey: autoIncrement() en `id` ya lo implica.
  @override
  List<String> get customConstraints => [
        'UNIQUE(canal, correlativo)',
        'CHECK (nivel_de_interes BETWEEN 0 AND 100)',
      ];
}

@DataClassName('Venta')
@TableIndex(name: 'idx_ventas_proceso', columns: {#idProcesoPersuasion})
@TableIndex(name: 'idx_ventas_cliente', columns: {#codCliente})
@TableIndex(name: 'idx_ventas_estrategia', columns: {#codEstrategia})
@TableIndex(name: 'idx_ventas_timestamp', columns: {#timestamp})
class Ventas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get canal => text()(); // C7 - antes canal_venta en detalle
  IntColumn get correlativo => integer()();
  TextColumn get idProcesoPersuasion =>
      text()(); // C1 - el campo que faltaba (G1)
  TextColumn get codCliente => text().references(Clientes, #codCliente)();
  TextColumn get codEstrategia =>
      text().nullable().references(Estrategias, #codEstrategia)();
  TextColumn get tipoTransaccion =>
      text().references(TiposTransaccion, #codTransaccion)();
  IntColumn get timestamp => integer()(); // epoch millis

  // Sin @override de primaryKey: autoIncrement() en `id` ya lo implica.
  @override
  List<String> get customConstraints => [
        'UNIQUE(canal, correlativo)',
      ];
}

@DataClassName('DetalleVentaData') // 'DetalleVenta' colisionaria con la clase Table
@TableIndex(name: 'idx_detalle_producto', columns: {#codLoteProducto})
class DetalleVenta extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ventaId =>
      integer().references(Ventas, #id, onDelete: KeyAction.cascade)(); // FK real
  TextColumn get codLoteProducto =>
      text().references(Productos, #codLoteProducto)();
  IntColumn get cantidad => integer()();
  IntColumn get precioUnitarioCentavos => integer()(); // snapshot del precio

  // Sin @override de primaryKey: autoIncrement() en `id` ya lo implica.
  @override
  List<String> get customConstraints => [
        'UNIQUE(venta_id, cod_lote_producto)',
      ];
}
