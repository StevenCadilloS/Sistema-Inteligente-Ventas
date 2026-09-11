import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/decision/adaptation_engine.dart';
import 'package:tienda_adaptativa/decision/learning/bandit_optimizer.dart';

import '../apoyo/fake_tienda_repository.dart';

/// Prueba de la fase 05 (docs/PLAN_ELVIS.md - el rubro de 8 puntos del
/// taller): valida que cada emocion produce una oferta distinta, que cada
/// decision queda registrada, y que la promocion que publica el administrador
/// convive con el descuento adaptativo sin pisarlo.
///
/// El catalogo ya no se siembra en una base SQLite en memoria: lo entrega un
/// doble del repositorio (test/apoyo/fake_tienda_repository.dart). Lo que se
/// prueba aqui son las reglas de decision; el esquema, la venta atomica y los
/// KPIs se prueban en SQL, en supabase/tests/.
void main() {
  late FakeTiendaRepository repo;
  late AdaptationEngine engine;
  const codCliente = 'C0000001';

  Producto p(
    String cod,
    String nombre,
    String? tipo,
    int precio, {
    int mostrado = 0,
    int stock = 10,
  }) => Producto(
    codLoteProducto: cod,
    nombreProducto: nombre,
    tipoProducto: tipo,
    precioUnitarioCentavos: precio,
    totalDisponible: stock,
    totalVecesMostrado: mostrado,
  );

  setUp(() {
    repo = FakeTiendaRepository(
      clientes: const [codCliente],
      productos: [
        p('P0000001', 'Audifonos Basicos', 'T00001', 5000), // el mas economico
        p('P0000002', 'Audifonos Premium', 'T00001', 25000), // el mas caro
        p('P0000003', 'Mouse Gamer', 'T00002', 8000, mostrado: 50), // otra categoria
      ],
      estrategias: const [
        Estrategia(
          codEstrategia: 'E0000001',
          nombreEstrategia: 'Sustituto economico',
        ),
      ],
    );
    engine = AdaptationEngine(repo, BanditOptimizer(repo));
  });

  tearDown(() => repo.cerrar());

  test('el descuento de la oferta es real: la venta congela el precio rebajado', () async {
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'enojo', // regla de descuento agresivo
      nivelDeInteres: 70,
    );

    expect(oferta.descuentoPorcentaje, 25);
    expect(
      oferta.precioFinalCentavos,
      oferta.producto.precioUnitarioCentavos * 75 ~/ 100,
    );

    await BanditOptimizer(repo).registrarRespuesta(
      idProcesoPersuasion: oferta.idProcesoPersuasion,
      aceptada: true,
      precioFinalCentavos: oferta.precioFinalCentavos,
    );

    final venta = repo.ventas.single;
    // Lo cobrado, no el precio de lista: si esto se rompe, el popup prometeria
    // un descuento que la base no registra.
    expect(venta.precioUnitarioCentavos, oferta.precioFinalCentavos);
    expect(
      venta.precioUnitarioCentavos,
      lessThan(oferta.producto.precioUnitarioCentavos),
    );
  });

  test('la venta descuenta el stock', () async {
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'triste',
      nivelDeInteres: 60,
    );
    final antes = repo.producto(oferta.producto.codLoteProducto).totalDisponible;

    await BanditOptimizer(repo).registrarRespuesta(
      idProcesoPersuasion: oferta.idProcesoPersuasion,
      aceptada: true,
    );

    expect(
      repo.producto(oferta.producto.codLoteProducto).totalDisponible,
      antes - 1,
    );
  });

  test('el sustituto es de la misma categoria y mas economico', () async {
    // P0000002 (Audifonos Premium, 25000, T00001). Su sustituto debe salir de
    // T00001 y costar menos: P0000001 (5000), no el Mouse de otra categoria.
    final rechazado = repo.producto('P0000002');

    final sustituto = await engine.sustitutoPara(rechazado);

    expect(sustituto, isNotNull);
    expect(sustituto!.tipoProducto, rechazado.tipoProducto);
    expect(
      sustituto.precioUnitarioCentavos,
      lessThan(rechazado.precioUnitarioCentavos),
    );
  });

  test('el sustituto respeta lo ya rechazado', () async {
    final rechazado = repo.producto('P0000002');

    // Excluido el unico candidato de su categoria, no queda alternativa.
    final sustituto = await engine.sustitutoPara(
      rechazado,
      excluir: {'P0000001'},
    );

    expect(sustituto, isNull);
  });

  test('la primera oferta va a precio de lista (conDescuento: false)', () async {
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'enojo', // la regla daria 25%
      nivelDeInteres: 70,
      conDescuento: false,
    );

    expect(oferta.descuentoPorcentaje, 0);
    expect(oferta.tieneDescuento, isFalse);
    expect(oferta.precioFinalCentavos, oferta.producto.precioUnitarioCentavos);
    // El texto no puede anunciar "0% de descuento".
    expect(oferta.texto, isNot(contains('0%')));
  });

  test('productoObjetivo fuerza la oferta sobre ese producto', () async {
    // 'triste' elegiria el mas economico (P0000001, 5000); se pide el caro.
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'triste',
      nivelDeInteres: 50,
      productoObjetivo: repo.producto('P0000002'),
    );

    expect(oferta.producto.codLoteProducto, 'P0000002');
    // La emocion sigue decidiendo el descuento aunque el producto sea fijo.
    expect(oferta.descuentoPorcentaje, 10);
  });

  test('tras un rechazo insiste con otro producto, no con el mismo', () async {
    final primera = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'triste',
      nivelDeInteres: 60,
    );

    final segunda = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'triste', // misma emocion: la regla sola devolveria lo mismo
      nivelDeInteres: 60,
      excluir: {primera.producto.codLoteProducto},
    );

    expect(
      segunda.producto.codLoteProducto,
      isNot(primera.producto.codLoteProducto),
    );
  });

  test('feliz es premium y va sin descuento', () async {
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'feliz',
      nivelDeInteres: 80,
    );

    expect(oferta.descuentoPorcentaje, 0);
    expect(oferta.tieneDescuento, isFalse);
    expect(oferta.precioFinalCentavos, oferta.producto.precioUnitarioCentavos);
  });

  test('triste -> el producto mas economico', () async {
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'triste',
      nivelDeInteres: 60,
    );
    expect(oferta.producto.codLoteProducto, 'P0000001');
  });

  test('feliz -> el producto mas caro (premium)', () async {
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'feliz',
      nivelDeInteres: 90,
    );
    expect(oferta.producto.codLoteProducto, 'P0000002');
  });

  test('neutral -> el producto mas mostrado (estandar)', () async {
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'neutral',
      nivelDeInteres: 50,
    );
    expect(oferta.producto.codLoteProducto, 'P0000003');
  });

  test('sorpresa -> el producto menos mostrado (novedad)', () async {
    // P0000003 lleva 50 exhibiciones; los otros dos, ninguna. Con empate a 0,
    // el desempate por codigo hace que salga siempre el mismo y el feed no
    // parpadee entre dos productos igual de nuevos.
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'sorpresa',
      nivelDeInteres: 75,
    );
    expect(oferta.producto.codLoteProducto, 'P0000001');
    expect(oferta.descuentoPorcentaje, 15);
  });

  test(
    'cada decision incrementa totalVecesMostrado - sin esto neutral/sorpresa '
    'nunca cambiarian de resultado',
    () async {
      expect(repo.producto('P0000001').totalVecesMostrado, 0);

      await engine.decidirOferta(
        codCliente: codCliente,
        emocion: 'triste', // elige P0000001 (el mas economico)
        nivelDeInteres: 60,
      );

      expect(repo.producto('P0000001').totalVecesMostrado, 1);
    },
  );

  test(
    'emocion no catalogada ("no_face" del clasificador, o una etiqueta nueva) '
    'cae a neutral en vez de crashear',
    () async {
      final oferta = await engine.decidirOferta(
        codCliente: codCliente,
        emocion: 'sin_clasificar',
        nivelDeInteres: 50,
      );

      // neutral -> el mas mostrado, igual que con 'neutral'.
      expect(oferta.producto.codLoteProducto, 'P0000003');
      // La interaccion se registra igual; traducir la emocion a un codigo de
      // gesto (o dejarlo nulo si no existe) es cosa del servidor.
      expect(repo.interacciones.single.emocion, 'sin_clasificar');
    },
  );

  test('enojo -> cambia de categoria respecto al ultimo producto mostrado', () async {
    // Primero se le muestra un producto de la categoria Audio (feliz).
    await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'feliz',
      nivelDeInteres: 80,
    );

    // Ahora se enoja: debe saltar a la categoria Accesorios (P0000003).
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'enojo',
      nivelDeInteres: 70,
    );
    expect(oferta.producto.tipoProducto, 'T00002');
  });

  test(
    'enojo sin historial cae al mas economico aunque no tenga categoria '
    'asignada (C6: tipoProducto es nullable)',
    () async {
      repo = FakeTiendaRepository(
        clientes: const [codCliente],
        productos: [
          p('P0000001', 'Audifonos Basicos', 'T00001', 5000),
          p('P0000004', 'Producto sin categoria', null, 100), // el mas barato
        ],
        estrategias: const [
          Estrategia(codEstrategia: 'E0000001', nombreEstrategia: 'Directo'),
        ],
      );
      engine = AdaptationEngine(repo, BanditOptimizer(repo));

      final oferta = await engine.decidirOferta(
        codCliente: codCliente, // sin interacciones previas
        emocion: 'enojo',
        nivelDeInteres: 70,
      );

      expect(oferta.producto.codLoteProducto, 'P0000004');
    },
  );

  test('cada decision registra la interaccion completa', () async {
    final oferta = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'sorpresa',
      nivelDeInteres: 75,
    );

    final fila = repo.interacciones.single;
    expect(fila.idProcesoPersuasion, oferta.idProcesoPersuasion);
    expect(fila.codCliente, codCliente);
    expect(fila.emocion, 'sorpresa');
    expect(fila.codLoteProducto, oferta.producto.codLoteProducto);
    expect(fila.codEstrategia, 'E0000001');
    expect(fila.nivelDeInteres, 75);
  });

  test('la regla eliminatoria: la oferta cambia sola sin intervencion manual', () async {
    final triste = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'triste',
      nivelDeInteres: 60,
    );
    final feliz = await engine.decidirOferta(
      codCliente: codCliente,
      emocion: 'feliz',
      nivelDeInteres: 60,
    );

    // Mismo cliente, mismo nivelDeInteres, unico input distinto: el gesto.
    expect(
      triste.producto.codLoteProducto,
      isNot(feliz.producto.codLoteProducto),
    );
  });

  test('un producto agotado no entra al catalogo ni se ofrece', () async {
    repo = FakeTiendaRepository(
      clientes: const [codCliente],
      productos: [
        p('P0000001', 'Agotado', 'T00001', 1000, stock: 0),
        p('P0000002', 'Disponible', 'T00001', 9000, stock: 3),
      ],
      estrategias: const [
        Estrategia(codEstrategia: 'E0000001', nombreEstrategia: 'Directo'),
      ],
    );
    engine = AdaptationEngine(repo, BanditOptimizer(repo));

    final catalogo = await engine.catalogoPara(
      codCliente: codCliente,
      emocion: 'triste', // pediria el mas barato, que es el agotado
    );

    expect(catalogo.map((p) => p.codLoteProducto), ['P0000002']);
  });

  // --------------- OFERTAS DEL ADMINISTRADOR ---------------

  group('promocion publicada por el administrador', () {
    test('se aplica aunque la emocion no conceda descuento', () async {
      // 'feliz' es premium: descuento adaptativo 0. La promocion de la tienda
      // no puede desaparecer por eso — el feed ya la esta anunciando.
      await repo.publicarOferta(
        'P0000002',
        descuento: 30,
        nombre: 'Semana de audio',
      );

      final oferta = await engine.decidirOferta(
        codCliente: codCliente,
        emocion: 'feliz',
        nivelDeInteres: 80,
      );

      expect(oferta.producto.codLoteProducto, 'P0000002');
      expect(oferta.descuentoPorcentaje, 30);
      expect(oferta.descuentoDelAdministrador, isTrue);
      expect(oferta.precioFinalCentavos, 25000 - (25000 * 30 ~/ 100));
      expect(oferta.texto, contains('Semana de audio'));
    });

    test('gana el descuento adaptativo cuando es mayor', () async {
      await repo.publicarOferta('P0000001', descuento: 10);

      final oferta = await engine.decidirOferta(
        codCliente: codCliente,
        emocion: 'enojo', // 25%
        nivelDeInteres: 70,
        productoObjetivo: repo.producto('P0000001'),
      );

      expect(oferta.descuentoPorcentaje, 25);
      expect(oferta.descuentoDelAdministrador, isFalse);
    });

    test('los descuentos nunca se suman', () async {
      await repo.publicarOferta('P0000001', descuento: 40);

      final oferta = await engine.decidirOferta(
        codCliente: codCliente,
        emocion: 'enojo', // 25%: sumados darian 65 y regalarian el producto
        nivelDeInteres: 70,
        productoObjetivo: repo.producto('P0000001'),
      );

      expect(oferta.descuentoPorcentaje, 40);
    });

    test('la oferta a precio de lista respeta la promocion vigente', () async {
      // Sin esto, el primer popup mostraria un precio MAS ALTO que el que el
      // cliente acaba de ver en el feed.
      await repo.publicarOferta('P0000001', descuento: 20);

      final oferta = await engine.decidirOferta(
        codCliente: codCliente,
        emocion: 'neutral',
        nivelDeInteres: 50,
        productoObjetivo: repo.producto('P0000001'),
        conDescuento: false,
      );

      expect(oferta.descuentoPorcentaje, 20);
      expect(oferta.precioFinalCentavos, repo.producto('P0000001').precioVigenteCentavos);
    });

    test('el catalogo publica el precio vigente ya rebajado', () async {
      await repo.publicarOferta('P0000001', descuento: 20);

      final catalogo = await engine.catalogoPara(
        codCliente: codCliente,
        emocion: 'neutral',
      );
      final rebajado = catalogo.firstWhere(
        (p) => p.codLoteProducto == 'P0000001',
      );

      expect(rebajado.enOferta, isTrue);
      expect(rebajado.precioVigenteCentavos, 4000);
      expect(rebajado.precioUnitarioCentavos, 5000, reason: 'el de lista no cambia');
    });
  });

  group('tope del descuento acumulado', () {
    /// La estrategia "Oferta relampago" (E0000004) suma 5 puntos al descuento
    /// de la emocion. Sobre enojo (25%) eso da 30%, que es lo buscado. El
    /// problema aparece al combinarlo con una promocion del administrador: la
    /// base topa `ofertas.descuento_porcentaje` en 90 justamente para no
    /// regalar el producto, pero ese tope no existe del lado de la app.
    test('relampago sobre enojo suma 5 puntos al descuento de la emocion', () async {
      final soloRelampago = FakeTiendaRepository(
        clientes: const [codCliente],
        productos: [p('P0000001', 'Audifonos Basicos', 'T00001', 5000)],
        estrategias: const [
          Estrategia(codEstrategia: 'E0000004', nombreEstrategia: 'Oferta relampago'),
        ],
      );
      addTearDown(soloRelampago.cerrar);
      final motor = AdaptationEngine(soloRelampago, BanditOptimizer(soloRelampago));

      final oferta = await motor.decidirOferta(
        codCliente: codCliente,
        emocion: 'enojo',
        nivelDeInteres: 50,
      );

      expect(oferta.descuentoPorcentaje, 30, reason: '25 de enojo + 5 de relampago');
    });

    test('el descuento nunca pasa del 90%, el mismo tope que impone la base', () async {
      final soloRelampago = FakeTiendaRepository(
        clientes: const [codCliente],
        productos: [p('P0000001', 'Audifonos Basicos', 'T00001', 5000)],
        estrategias: const [
          Estrategia(codEstrategia: 'E0000004', nombreEstrategia: 'Oferta relampago'),
        ],
      );
      addTearDown(soloRelampago.cerrar);
      final motor = AdaptationEngine(soloRelampago, BanditOptimizer(soloRelampago));

      // El maximo que acepta la base para una promocion publicada.
      await soloRelampago.publicarOferta('P0000001', descuento: 90);

      final oferta = await motor.decidirOferta(
        codCliente: codCliente,
        emocion: 'enojo',
        nivelDeInteres: 50,
      );

      expect(oferta.descuentoPorcentaje, lessThanOrEqualTo(90));
      expect(
        oferta.precioFinalCentavos,
        greaterThan(0),
        reason: 'un precio final de 0 o negativo ensucia todos los KPIs de monto',
      );
    });
  });

  group('estrategias que no tocan el precio', () {
    /// E0000002 (envio gratis) y E0000003 (recomendacion premium) devuelven 0
    /// como descuento adaptativo a proposito: persuaden sin rebajar. Pero la
    /// promocion que publica el administrador es independiente de la
    /// estrategia, y debe seguir aplicandose igual.
    Future<Oferta> ofertaCon(String codEstrategia, {int? promocionAdmin}) async {
      final r = FakeTiendaRepository(
        clientes: const [codCliente],
        productos: [p('P0000001', 'Audifonos Basicos', 'T00001', 5000)],
        estrategias: [
          Estrategia(codEstrategia: codEstrategia, nombreEstrategia: 'X'),
        ],
      );
      addTearDown(r.cerrar);
      if (promocionAdmin != null) {
        await r.publicarOferta('P0000001', descuento: promocionAdmin);
      }
      return AdaptationEngine(r, BanditOptimizer(r)).decidirOferta(
        codCliente: codCliente,
        emocion: 'triste', // base 10%
        nivelDeInteres: 50,
      );
    }

    test('envio gratis no rebaja el precio pese a la emocion', () async {
      final oferta = await ofertaCon('E0000002');
      expect(oferta.descuentoPorcentaje, 0);
      expect(oferta.texto, contains('envio gratis'));
    });

    test('la promocion del administrador se aplica aunque la estrategia no rebaje', () async {
      final oferta = await ofertaCon('E0000002', promocionAdmin: 20);

      expect(oferta.descuentoPorcentaje, 20, reason: 'la promocion del admin manda');
      expect(oferta.descuentoDelAdministrador, isTrue);
      expect(
        oferta.precioFinalCentavos,
        4000,
        reason: 'el precio ofrecido debe coincidir con el que anuncia el feed',
      );
    });
  });
}
