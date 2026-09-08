import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/database/app_database.dart';
import 'package:tienda_adaptativa/data/database/catalogo_demo.dart';

/// El sembrado corre en cada arranque de la app (main.dart), asi que tiene
/// que ser idempotente: sin eso, cada vez que el cliente abre la tienda se
/// duplicarian los 16 productos.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').getSingle(); // dispara onCreate/seed
  });

  tearDown(() => db.close());

  test('siembra el catalogo de demostracion', () async {
    await sembrarCatalogoDemo(db);

    final productos = await db.select(db.productos).get();
    final categorias = await db.select(db.tiposProducto).get();
    final estrategias = await db.select(db.estrategias).get();

    expect(productos, hasLength(16));
    expect(categorias, hasLength(4));
    expect(estrategias, hasLength(4));
  });

  test('sembrar dos veces no duplica nada', () async {
    await sembrarCatalogoDemo(db);
    await sembrarCatalogoDemo(db);

    expect(await db.select(db.productos).get(), hasLength(16));
    expect(await db.select(db.estrategias).get(), hasLength(4));
  });

  test('los productos quedan con precio y stock utilizables', () async {
    await sembrarCatalogoDemo(db);

    final productos = await db.select(db.productos).get();

    expect(productos.every((p) => p.precioUnitarioCentavos > 0), isTrue);
    expect(productos.every((p) => p.totalDisponible > 0), isTrue);
    expect(productos.every((p) => p.activo), isTrue);
    // Las reglas de 'neutral' y 'sorpresa' ordenan por totalVecesMostrado:
    // si todos arrancaran en cero, ambas darian el mismo resultado.
    expect(productos.map((p) => p.totalVecesMostrado).toSet(), hasLength(16));
  });
}
