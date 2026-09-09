import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/data/repositories/tienda_repository.dart';
import 'package:tienda_adaptativa/decision/learning/bandit_optimizer.dart';

import '../../apoyo/fake_tienda_repository.dart';

/// Aprendizaje UCB1 (docs/PLAN_ELVIS.md fase 06).
///
/// Con la base compartida, exitos e intentos dejan de contarse por dispositivo:
/// los cuenta el servidor sobre las bitacoras de todos los usuarios (vista
/// `v_estrategia_desempeno`). Lo que se prueba aqui es la decision que toma el
/// bandit con esos numeros; que la vista los calcule bien se prueba en
/// supabase/tests/03_batch_y_kpis.sql.
void main() {
  late FakeTiendaRepository repo;
  late BanditOptimizer bandit;
  const codCliente = 'C0000001';

  setUp(() {
    repo = FakeTiendaRepository(
      clientes: const [codCliente],
      productos: const [
        Producto(
          codLoteProducto: 'P0000001',
          nombreProducto: 'Producto de prueba',
          precioUnitarioCentavos: 15000,
          totalDisponible: 10,
        ),
      ],
      estrategias: const [
        Estrategia(codEstrategia: 'E0000001', nombreEstrategia: 'Sustituto'),
        Estrategia(codEstrategia: 'E0000002', nombreEstrategia: 'Descuento'),
      ],
    );
    bandit = BanditOptimizer(repo);
  });

  tearDown(() => repo.cerrar());

  void registrarInteraccion({
    required String idProcesoPersuasion,
    required String codEstrategia,
  }) {
    repo.registrarInteraccionEnProceso(
      idProcesoPersuasion: idProcesoPersuasion,
      codCliente: codCliente,
      codLoteProducto: 'P0000001',
      codEstrategia: codEstrategia,
    );
  }

  test('prioriza una estrategia nunca aplicada sobre una ya probada', () async {
    // E0000001 ya se aplico una vez; E0000002 nunca.
    registrarInteraccion(
      idProcesoPersuasion: 'PP00000001',
      codEstrategia: 'E0000001',
    );

    final elegida = await bandit.seleccionarEstrategia();

    expect(elegida?.codEstrategia, 'E0000002');
  });

  test(
    'un proceso con varias filas para la misma estrategia cuenta como 1 '
    'intento, no como una fila por intento',
    () async {
      // E0000001: UN solo proceso que muestra la misma estrategia en varias
      // interacciones y que SI cierra en venta -> conversion real del 100%.
      for (var i = 0; i < 4; i++) {
        registrarInteraccion(
          idProcesoPersuasion: 'PP00000001',
          codEstrategia: 'E0000001',
        );
      }
      await bandit.registrarRespuesta(
        idProcesoPersuasion: 'PP00000001',
        aceptada: true,
      );

      // E0000002: un proceso distinto, que NO cierra en venta.
      registrarInteraccion(
        idProcesoPersuasion: 'PP00000002',
        codEstrategia: 'E0000002',
      );
      await bandit.registrarRespuesta(
        idProcesoPersuasion: 'PP00000002',
        aceptada: false,
      );

      // Contando filas crudas, E0000001 tendria 4 intentos y una tasa de
      // conversion diluida a 25%, perdiendo frente a E0000002 (0 exitos pero
      // "menos intentos") por el termino de exploracion de UCB1. Contando
      // procesos distintos (correcto), E0000001 tiene 100% de conversion en su
      // unico proceso y debe ganar.
      final elegida = await bandit.seleccionarEstrategia();

      expect(elegida?.codEstrategia, 'E0000001');
    },
  );

  test('una vez que todas se probaron, favorece la de mejor tasa de conversion', () async {
    // E0000001: 1 intento, 1 exito (100%).
    registrarInteraccion(
      idProcesoPersuasion: 'PP00000001',
      codEstrategia: 'E0000001',
    );
    await bandit.registrarRespuesta(
      idProcesoPersuasion: 'PP00000001',
      aceptada: true,
    );

    // E0000002: 3 intentos, 0 exitos (0%).
    for (final id in ['PP00000002', 'PP00000003', 'PP00000004']) {
      registrarInteraccion(
        idProcesoPersuasion: id,
        codEstrategia: 'E0000002',
      );
      await bandit.registrarRespuesta(idProcesoPersuasion: id, aceptada: false);
    }

    final elegida = await bandit.seleccionarEstrategia();

    expect(elegida?.codEstrategia, 'E0000001');
  });

  test('registrarRespuesta(aceptada: true) crea la venta con su detalle', () async {
    registrarInteraccion(
      idProcesoPersuasion: 'PP00000001',
      codEstrategia: 'E0000001',
    );

    await bandit.registrarRespuesta(
      idProcesoPersuasion: 'PP00000001',
      aceptada: true,
    );

    final venta = repo.ventas.single;
    expect(venta.idProcesoPersuasion, 'PP00000001');
    expect(venta.codEstrategia, 'E0000001');
    expect(venta.codLoteProducto, 'P0000001');
    expect(venta.precioUnitarioCentavos, 15000); // snapshot del precio
  });

  test(
    'registrarRespuesta(aceptada: false) NO crea venta (asi se infiere el rechazo)',
    () async {
      registrarInteraccion(
        idProcesoPersuasion: 'PP00000001',
        codEstrategia: 'E0000001',
      );

      await bandit.registrarRespuesta(
        idProcesoPersuasion: 'PP00000001',
        aceptada: false,
      );

      expect(repo.ventas, isEmpty);
    },
  );

  test('sin estrategias activas devuelve null en vez de fallar', () async {
    repo.definirEstrategias(const [
      Estrategia(
        codEstrategia: 'E0000001',
        nombreEstrategia: 'Apagada',
        activo: false,
      ),
    ]);

    final elegida = await bandit.seleccionarEstrategia();

    expect(elegida, isNull);
  });

  test('si el producto se agoto mientras tanto, la venta falla y se avisa', () async {
    // Caso nuevo con la base compartida: otro cliente pudo llevarse la ultima
    // unidad entre que se genero la oferta y que esta persona la acepto. El
    // servidor rechaza la venta y el error debe llegar tipado hasta la UI, no
    // como un fallo generico.
    repo = FakeTiendaRepository(
      clientes: const [codCliente],
      productos: const [
        Producto(
          codLoteProducto: 'P0000001',
          nombreProducto: 'Ultima unidad',
          precioUnitarioCentavos: 15000,
          totalDisponible: 0,
        ),
      ],
      estrategias: const [
        Estrategia(codEstrategia: 'E0000001', nombreEstrategia: 'Sustituto'),
      ],
    );
    bandit = BanditOptimizer(repo);
    repo.registrarInteraccionEnProceso(
      idProcesoPersuasion: 'PP00000001',
      codCliente: codCliente,
      codLoteProducto: 'P0000001',
      codEstrategia: 'E0000001',
    );

    expect(
      () => bandit.registrarRespuesta(
        idProcesoPersuasion: 'PP00000001',
        aceptada: true,
      ),
      throwsA(isA<SinStockException>()),
    );
  });
}
