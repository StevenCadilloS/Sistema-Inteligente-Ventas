import 'package:drift/drift.dart';

import 'app_database.dart';

/// Catalogo de demostracion (productos, categorias y estrategias).
///
/// Va aparte de [AppDatabase.seedCatalogos] a proposito: seedCatalogos corre
/// en `onCreate`, que tambien dispara `AppDatabase.forTesting` — y los tests
/// siembran sus propios productos y esperan contarlos exactos. Sembrar aqui
/// mantiene los 35 tests intactos.
///
/// Sin esto la app queda con `productos` vacia y `decidirOferta` no tiene
/// nada que ofrecer.
Future<void> sembrarCatalogoDemo(AppDatabase db) async {
  final yaSembrado =
      await (db.select(db.productos)..limit(1)).getSingleOrNull();
  if (yaSembrado != null) return;

  final ahora = DateTime.now().millisecondsSinceEpoch;

  await db.batch((b) {
    b.insertAll(db.tiposProducto, [
      TiposProductoCompanion.insert(
          tipoProducto: 'T00001', nombreTipoProducto: 'Tecnologia'),
      TiposProductoCompanion.insert(
          tipoProducto: 'T00002', nombreTipoProducto: 'Hogar'),
      TiposProductoCompanion.insert(
          tipoProducto: 'T00003', nombreTipoProducto: 'Moda'),
      TiposProductoCompanion.insert(
          tipoProducto: 'T00004', nombreTipoProducto: 'Belleza'),
    ]);

    // totalVecesMostrado sembrado y variado a proposito: las reglas de
    // `neutral` (lo mas mostrado) y `sorpresa` (lo menos mostrado) necesitan
    // un historial para ordenar distinto desde el primer arranque.
    b.insertAll(db.productos, [
      _producto('P0000001', 'Audifonos Bluetooth', 'T00001', 4990, ahora,
          mostrado: 42, stock: 30),
      _producto('P0000002', 'Smartwatch Deportivo', 'T00001', 12900, ahora,
          mostrado: 18, stock: 15),
      _producto('P0000003', 'Parlante Portatil', 'T00001', 8500, ahora,
          mostrado: 27, stock: 22),
      _producto('P0000004', 'Cargador Inalambrico', 'T00001', 3590, ahora,
          mostrado: 9, stock: 40),
      _producto('P0000005', 'Laptop Ultradelgada', 'T00001', 289900, ahora,
          mostrado: 5, stock: 4),
      _producto('P0000006', 'Set de Sartenes', 'T00002', 15900, ahora,
          mostrado: 31, stock: 12),
      _producto('P0000007', 'Lampara LED de Escritorio', 'T00002', 4290, ahora,
          mostrado: 14, stock: 25),
      _producto('P0000008', 'Organizador Modular', 'T00002', 2590, ahora,
          mostrado: 3, stock: 50),
      _producto('P0000009', 'Aspiradora Robot', 'T00002', 79900, ahora,
          mostrado: 21, stock: 6),
      _producto('P0000010', 'Polo Basico de Algodon', 'T00003', 2990, ahora,
          mostrado: 38, stock: 60),
      _producto('P0000011', 'Zapatillas Urbanas', 'T00003', 13900, ahora,
          mostrado: 45, stock: 18),
      _producto('P0000012', 'Mochila Antirrobo', 'T00003', 8900, ahora,
          mostrado: 12, stock: 20),
      _producto('P0000013', 'Casaca Impermeable', 'T00003', 19900, ahora,
          mostrado: 7, stock: 10),
      _producto('P0000014', 'Kit de Skincare', 'T00004', 6990, ahora,
          mostrado: 25, stock: 28),
      _producto('P0000015', 'Secadora de Cabello', 'T00004', 9900, ahora,
          mostrado: 16, stock: 14),
      _producto('P0000016', 'Perfume Citrico 100ml', 'T00004', 1890, ahora,
          mostrado: 1, stock: 35),
    ]);

    b.insertAll(db.estrategias, [
      EstrategiasCompanion.insert(
          codEstrategia: 'E0000001', nombreEstrategia: 'Descuento directo'),
      EstrategiasCompanion.insert(
          codEstrategia: 'E0000002', nombreEstrategia: 'Envio gratis'),
      EstrategiasCompanion.insert(
          codEstrategia: 'E0000003',
          nombreEstrategia: 'Recomendacion premium'),
      EstrategiasCompanion.insert(
          codEstrategia: 'E0000004', nombreEstrategia: 'Oferta relampago'),
    ]);
  });
}

ProductosCompanion _producto(
  String cod,
  String nombre,
  String tipo,
  int precioCentavos,
  int fecha, {
  required int mostrado,
  required int stock,
}) {
  return ProductosCompanion.insert(
    codLoteProducto: cod,
    nombreProducto: nombre,
    tipoProducto: Value(tipo),
    precioUnitarioCentavos: precioCentavos,
    fechaCreacionStock: fecha,
    totalDisponible: Value(stock),
    totalVecesMostrado: Value(mostrado),
  );
}
