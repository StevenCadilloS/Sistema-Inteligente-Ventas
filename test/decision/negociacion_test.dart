import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/decision/negociacion.dart';

/// La regla central del sistema: la emocion no calcula el descuento, solo
/// decide si el puntero se queda donde esta o avanza por una escalera que un
/// administrador configuro antes.
void main() {
  Producto p({int precio = 250000}) => Producto(
    idProducto: 1,
    nombre: 'Laptop Lenovo IdeaPad',
    precioCentavos: precio,
    stock: 10,
    tieneOfertas: true,
  );

  EscalonOferta escalon(int orden, int pct, int precioFinal) => EscalonOferta(
    orden: orden,
    idOferta: orden,
    nombreOferta: 'Descuento $pct%',
    tipo: 'Descuento',
    porcentajeDescuento: pct,
    precioFinalCentavos: precioFinal,
  );

  // La escalera sembrada para la Laptop Lenovo: 10%, 20%, 30%.
  List<EscalonOferta> escaleraCompleta() => [
    escalon(1, 10, 225000),
    escalon(2, 20, 200000),
    escalon(3, 30, 175000),
  ];

  group('clasificacion de la respuesta', () {
    const clasificador = ClasificadorRespuesta();

    test('happy y surprise son favorables', () {
      expect(
        clasificador.clasificar(['feliz', 'feliz', 'sorpresa']),
        Respuesta.favorable,
      );
    });

    test('sad y angry son desfavorables', () {
      expect(
        clasificador.clasificar(['triste', 'enojo', 'triste']),
        Respuesta.desfavorable,
      );
    });

    test('neutral cuenta como desfavorable', () {
      // Decision de producto, tomada a sabiendas: la cara en reposo frente a
      // una pantalla suele clasificarse como neutral, asi que la mayoria de
      // los clientes vera avanzar la escalera.
      expect(
        clasificador.clasificar(['neutral', 'neutral', 'neutral']),
        Respuesta.desfavorable,
      );
    });

    test('gana el grupo mayoritario, no la ultima lectura', () {
      // 5 favorables contra 3 desfavorables: favorable, aunque la ultima
      // lectura sea triste. Una sola prediccion no decide.
      expect(
        clasificador.clasificar([
          'feliz', 'feliz', 'sorpresa', 'feliz', 'sorpresa',
          'neutral', 'neutral', 'triste',
        ]),
        Respuesta.favorable,
      );
    });

    test('el empate se resuelve como favorable: ante la duda no se rebaja', () {
      expect(
        clasificador.clasificar(['feliz', 'sorpresa', 'neutral', 'triste']),
        Respuesta.favorable,
      );
    });

    test('no_face no vota', () {
      // Cuatro no_face y una sola lectura real: no alcanza el minimo de 2.
      expect(
        clasificador.clasificar([
          'no_face', 'no_face', 'no_face', 'no_face', 'feliz',
        ]),
        Respuesta.sinSenal,
        reason: 'los no_face no cuentan como votos',
      );

      // Y con dos lecturas reales si decide, aunque vengan rodeadas de
      // no_face: perder el rostro un instante no invalida lo observado.
      expect(
        clasificador.clasificar([
          'no_face', 'triste', 'no_face', 'triste', 'no_face',
        ]),
        Respuesta.desfavorable,
      );
    });

    test('sin lecturas suficientes no hay senal', () {
      expect(clasificador.clasificar([]), Respuesta.sinSenal);
      expect(clasificador.clasificar(['feliz']), Respuesta.sinSenal);
    });

    test('acepta tambien las etiquetas en ingles', () {
      expect(
        clasificador.clasificar(['happy', 'surprise', 'happy']),
        Respuesta.favorable,
      );
      expect(
        clasificador.clasificar(['sad', 'angry', 'neutral']),
        Respuesta.desfavorable,
      );
    });
  });

  group('la negociacion empieza en el precio normal', () {
    test('el primer precio es el de lista, sin descuento', () {
      final n = Negociacion(producto: p(), escalera: escaleraCompleta());

      expect(n.enPrecioNormal, isTrue);
      expect(n.precioActualCentavos, 250000);
      expect(n.idOfertaActual, isNull, reason: 'la venta se cierra sin oferta');
      expect(n.descuentoCentavos, 0);
    });

    test('el mensaje inicial no anuncia ningun descuento', () {
      final n = Negociacion(producto: p(), escalera: escaleraCompleta());
      expect(n.mensaje, 'Laptop Lenovo IdeaPad a S/2500.00.');
    });
  });

  group('la emocion avanza el puntero, no calcula el descuento', () {
    test('una respuesta favorable mantiene el precio', () {
      final n = Negociacion(producto: p(), escalera: escaleraCompleta());

      expect(n.siguientePaso(Respuesta.favorable), PasoNegociacion.mantener);
      expect(n.precioActualCentavos, 250000, reason: 'no se movio');
    });

    test('sin senal tampoco se mueve', () {
      final n = Negociacion(producto: p(), escalera: escaleraCompleta());
      expect(n.siguientePaso(Respuesta.sinSenal), PasoNegociacion.mantener);
    });

    test('una respuesta desfavorable avanza al siguiente escalon', () {
      final n = Negociacion(producto: p(), escalera: escaleraCompleta());

      expect(n.siguientePaso(Respuesta.desfavorable), PasoNegociacion.avanzar);
      expect(n.avanzar(), isTrue);

      expect(n.precioActualCentavos, 225000, reason: 'el primer escalon: 10%');
      expect(n.idOfertaActual, 1);
      expect(n.descuentoCentavos, 25000);
      expect(n.enPrecioNormal, isFalse);
    });

    test('los escalones se recorren en orden y cada uno rebaja mas', () {
      final n = Negociacion(producto: p(), escalera: escaleraCompleta());
      final precios = <int>[n.precioActualCentavos];

      while (n.avanzar()) {
        precios.add(n.precioActualCentavos);
      }

      expect(precios, [250000, 225000, 200000, 175000]);
      for (var i = 1; i < precios.length; i++) {
        expect(
          precios[i],
          lessThan(precios[i - 1]),
          reason: 'avanzar tiene que mejorar la oferta, nunca empeorarla',
        );
      }
    });
  });

  group('final de la escalera', () {
    test('cuando se acaban los escalones, la interaccion termina', () {
      final n = Negociacion(producto: p(), escalera: escaleraCompleta());
      while (n.avanzar()) {}

      expect(n.quedanEscalones, isFalse);
      expect(n.siguientePaso(Respuesta.desfavorable), PasoNegociacion.terminar);
      expect(n.avanzar(), isFalse, reason: 'no hay a donde avanzar');
      expect(n.precioActualCentavos, 175000, reason: 'se queda en el ultimo');
    });

    test('un producto sin ofertas se queda siempre en el precio normal', () {
      // README regla 8: si no hay oferta, la emocion da igual.
      final n = Negociacion(producto: p(), escalera: const []);

      expect(n.quedanEscalones, isFalse);
      expect(n.siguientePaso(Respuesta.desfavorable), PasoNegociacion.terminar);
      expect(n.precioActualCentavos, 250000);
      expect(n.idOfertaActual, isNull);
    });
  });

  group('combos', () {
    test('un combo fija el precio final en vez de rebajar un porcentaje', () {
      final n = Negociacion(
        producto: p(precio: 30000),
        escalera: const [
          EscalonOferta(
            orden: 1,
            idOferta: 4,
            nombreOferta: 'Combo Gamer',
            tipo: 'Combo',
            precioFinalCentavos: 20000,
          ),
        ],
      );
      n.avanzar();

      expect(n.escalonActual!.esCombo, isTrue);
      expect(n.escalonActual!.porcentajeDescuento, isNull);
      expect(n.precioActualCentavos, 20000);
      expect(n.mensaje, contains('Combo Gamer'));
      expect(
        n.mensaje,
        isNot(contains('%')),
        reason: 'un combo no tiene porcentaje que anunciar',
      );
    });
  });

  group('mensajes', () {
    test('el mensaje anuncia el porcentaje y el precio del escalon', () {
      final n = Negociacion(producto: p(), escalera: escaleraCompleta());
      n.avanzar();

      expect(n.mensaje, contains('10%'));
      expect(n.mensaje, contains('S/2250.00'));
    });
  });

  group('rechazo explicito', () {
    /// Pulsar "No, gracias" es una respuesta desfavorable declarada, asi que
    /// hace lo mismo que una cara desfavorable: avanzar. Antes el boton
    /// cerraba la interaccion entera y el cliente nunca veia la segunda
    /// oferta — justo lo contrario de lo que describe el README.
    test('rechazar lleva al siguiente escalon, no al final', () {
      final n = Negociacion(producto: p(), escalera: escaleraCompleta());

      expect(n.siguientePaso(Respuesta.desfavorable), PasoNegociacion.avanzar);
      n.avanzar();
      expect(n.precioActualCentavos, 225000);

      expect(n.siguientePaso(Respuesta.desfavorable), PasoNegociacion.avanzar);
      n.avanzar();
      expect(n.precioActualCentavos, 200000);
    });

    test('rechazar en el ultimo escalon si termina', () {
      final n = Negociacion(producto: p(), escalera: escaleraCompleta());
      while (n.avanzar()) {}

      expect(n.siguientePaso(Respuesta.desfavorable), PasoNegociacion.terminar);
    });
  });

  group('minimo de votos', () {
    /// Cada lectura del modulo nativo ya viene filtrada por 26 frames
    /// consecutivos (~1,3 s), asi que dos lecturas son ~3 s de cara sostenida:
    /// suficiente para decidir. Con el minimo en 3 se perdian ventanas enteras.
    test('dos lecturas bastan para decidir', () {
      const c = ClasificadorRespuesta();
      expect(c.clasificar(['triste', 'triste']), Respuesta.desfavorable);
      expect(c.clasificar(['feliz', 'feliz']), Respuesta.favorable);
    });

    test('una sola lectura sigue siendo insuficiente', () {
      const c = ClasificadorRespuesta();
      expect(c.clasificar(['triste']), Respuesta.sinSenal);
    });
  });
}
