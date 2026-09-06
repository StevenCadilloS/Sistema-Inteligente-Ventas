import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Base de datos del Sistema Cierre de Ventas (docs/ESQUEMA_CORREGIDO.md,
/// docs/MODELO_ANDROID_ROOM.md traducido a drift). Ver docs/PLAN_ELVIS.md
/// fase 02.
@DriftDatabase(
  tables: [
    TiposCliente,
    TiposProducto,
    Gestos,
    TiposTransaccion,
    Clientes,
    Productos,
    Estrategias,
    Interacciones,
    Ventas,
    DetalleVenta,
  ],
  include: {'queries.drift'},
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedCatalogos();
        },
      );

  /// Los 4 catalogos deben existir ANTES que cualquier fila de bitacora,
  /// o las FK fallan (docs/PLAN_ELVIS.md seccion 6, trampa #2).
  ///
  /// El mapeo de gestos son las 5 clases del clasificador FER-2013 que ya
  /// produce EmotionDetector.kt (triste/feliz/sorpresa/neutral/enojo) -
  /// cierra la FK huerfana G2 (corrección C2).
  Future<void> seedCatalogos() async {
    await batch((b) {
      b.insertAll(
        tiposCliente,
        [
          TiposClienteCompanion.insert(
              codTipoCliente: 'T00001', nombreTipoCliente: 'Nuevo'),
          TiposClienteCompanion.insert(
              codTipoCliente: 'T00002', nombreTipoCliente: 'Frecuente'),
          TiposClienteCompanion.insert(
              codTipoCliente: 'T00003', nombreTipoCliente: 'VIP'),
        ],
      );

      b.insertAll(
        gestos,
        [
          GestosCompanion.insert(codGesto: 'G0000001', nombreGesto: 'triste'),
          GestosCompanion.insert(codGesto: 'G0000002', nombreGesto: 'feliz'),
          GestosCompanion.insert(
              codGesto: 'G0000003', nombreGesto: 'sorpresa'),
          GestosCompanion.insert(codGesto: 'G0000004', nombreGesto: 'neutral'),
          GestosCompanion.insert(codGesto: 'G0000005', nombreGesto: 'enojo'),
        ],
      );

      b.insertAll(
        tiposTransaccion,
        [
          TiposTransaccionCompanion.insert(
              codTransaccion: 'TRX0001', tipoTrx: 'oferta_aceptada'),
          TiposTransaccionCompanion.insert(
              codTransaccion: 'TRX0002', tipoTrx: 'oferta_rechazada'),
        ],
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tienda_adaptativa.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // SQLite no valida FK por defecto (a diferencia de Room). Hay que
        // activarlo en cada conexion o la correccion C11 (sin centinela
        // 00000000) queda sin efecto. Ver docs/PLAN_ELVIS.md trampa #1.
        db.execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}
