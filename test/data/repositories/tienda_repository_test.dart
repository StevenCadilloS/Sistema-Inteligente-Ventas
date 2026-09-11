import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/data/repositories/tienda_repository.dart';

import '../../apoyo/fake_tienda_repository.dart';

/// El contrato con el servidor, visto desde la app.
///
/// Lo que se prueba aqui es que la app entienda bien las reglas; que el
/// servidor las imponga de verdad se prueba en SQL (supabase/tests/). Las dos
/// mitades tienen que coincidir: si este doble fuera mas permisivo, las
/// pruebas pasarian y la app fallaria contra la base real.
///
/// Ninguna operacion recibe el id del cliente: sale de la sesion. Es lo que
/// impide pedir el historial de otra persona o gastarle sus ofertas del dia.
void main() {
  late FakeTiendaRepository repo;

  const idLenovo = 1;
  const idHp = 2;

  Producto p(int id, String nombre, int precio, {int stock = 10}) => Producto(
    idProducto: id,
    nombre: nombre,
    precioCentavos: precio,
    stock: stock,
    tieneOfertas: id == idLenovo,
  );

  EscalonOferta escalon(int orden, int pct, int precioFinal) => EscalonOferta(
    orden: orden,
    idOferta: orden,
    nombreOferta: 'Descuento $pct%',
    tipo: 'Descuento',
    porcentajeDescuento: pct,
    precioFinalCentavos: precioFinal,
  );

  /// Crea un cliente y deja su sesion abierta.
  Future<int> entrarComo(String nombre) async {
    repo.iniciarSesion(null);
    return repo.registrarCliente(nombre: nombre);
  }

  setUp(() {
    repo = FakeTiendaRepository(
      productos: [
        p(idLenovo, 'Laptop Lenovo IdeaPad', 250000),
        p(idHp, 'Laptop HP Pavilion', 280000), // sin ofertas, como la semilla
      ],
      escaleras: {
        idLenovo: [
          escalon(1, 10, 225000),
          escalon(2, 20, 200000),
          escalon(3, 30, 175000),
        ],
      },
    );
  });

  tearDown(() => repo.cerrar());

  group('sin sesion', () {
    test('el catalogo se puede leer sin identificarse', () async {
      // Mirar el escaparate no exige cuenta; negociar si.
      expect(await repo.catalogo(), isNotEmpty);
    });

    test('no se pueden pedir ofertas', () async {
      expect(
        () => repo.ofertasDe(idLenovo),
        throwsA(isA<SinSesionException>()),
      );
    });

    test('no se puede comprar', () async {
      expect(
        () => repo.registrarVenta(idProducto: idLenovo),
        throwsA(isA<SinSesionException>()),
      );
    });

    test('no se puede leer el historial', () async {
      expect(() => repo.historial(), throwsA(isA<SinSesionException>()));
    });

    test('no hay derecho a ofertas', () async {
      expect(await repo.puedeUsarOferta(), isFalse);
    });
  });

  group('escalera de ofertas', () {
    test('viene ordenada por escalon', () async {
      await entrarComo('Ana');
      final escalera = await repo.ofertasDe(idLenovo);

      expect(escalera.map((e) => e.orden), [1, 2, 3]);
      expect(escalera.map((e) => e.precioFinalCentavos), [225000, 200000, 175000]);
    });

    test('un producto sin ofertas devuelve una escalera vacia', () async {
      await entrarComo('Ana');
      expect(await repo.ofertasDe(idHp), isEmpty);
    });
  });

  group('limite de dos ofertas por dia', () {
    test('un cliente nuevo puede usar ofertas', () async {
      await entrarComo('Ana');
      expect(await repo.puedeUsarOferta(), isTrue);
    });

    test('cuentan las compras, no las que llevaron oferta', () async {
      await entrarComo('Ana');

      // Dos compras a precio normal: ninguna uso oferta, pero el cupo se
      // consume igual. Es la regla del README, y conviene que sorprenda aqui
      // y no en produccion.
      await repo.registrarVenta(idProducto: idHp);
      expect(await repo.puedeUsarOferta(), isTrue);

      await repo.registrarVenta(idProducto: idHp);
      expect(await repo.puedeUsarOferta(), isFalse);
    });

    test('sin cupo, la escalera viene vacia', () async {
      final id = await entrarComo('Ana');
      repo.agotarCupoDe(id);

      expect(
        await repo.ofertasDe(idLenovo),
        isEmpty,
        reason: 'la app no tiene que saber por que: simplemente no negocia',
      );
    });

    test('el servidor rechaza la venta con oferta sin cupo', () async {
      final id = await entrarComo('Ana');
      repo.agotarCupoDe(id);

      // Aunque la app se saltara la comprobacion previa, el servidor no.
      expect(
        () => repo.registrarVenta(idProducto: idLenovo, idOferta: 1),
        throwsA(isA<LimiteOfertasException>()),
      );
    });

    test('sin cupo todavia se puede comprar a precio normal', () async {
      final id = await entrarComo('Ana');
      repo.agotarCupoDe(id);

      final venta = await repo.registrarVenta(idProducto: idLenovo);
      expect(venta, isPositive, reason: 'el limite es de ofertas, no de compras');
    });

    test('el cupo se renueva al dia siguiente', () async {
      repo.ahora = () => DateTime(2026, 9, 11, 10);
      final id = await entrarComo('Ana');
      repo.agotarCupoDe(id);
      expect(await repo.puedeUsarOferta(), isFalse);

      repo.ahora = () => DateTime(2026, 9, 12, 10);
      expect(await repo.puedeUsarOferta(), isTrue);
    });

    test('el cupo de un cliente no consume el de otro', () async {
      // Sin identidad esto era imposible de garantizar: bastaba con
      // reinstalar la app para volver a tener ofertas.
      final ana = await entrarComo('Ana');
      repo.agotarCupoDe(ana);
      expect(await repo.puedeUsarOferta(), isFalse);

      await entrarComo('Carlos');
      expect(await repo.puedeUsarOferta(), isTrue);
    });
  });

  group('identidad', () {
    test('volver a registrarse con la sesion abierta no crea otro cliente', () async {
      final primero = await entrarComo('Ana');
      final segundo = await repo.registrarCliente(nombre: 'Ana');

      expect(segundo, primero, reason: 'la ficha ya existia');
    });

    test('cada cliente ve solo sus compras', () async {
      await entrarComo('Ana');
      await repo.registrarVenta(idProducto: idHp);
      expect((await repo.historial()).length, 1);

      await entrarComo('Carlos');
      expect(
        await repo.historial(),
        isEmpty,
        reason: 'el historial sale de la sesion, no de un parametro',
      );
    });
  });

  group('venta', () {
    test('a precio normal se cobra el precio de lista', () async {
      await entrarComo('Ana');
      await repo.registrarVenta(idProducto: idLenovo);

      final historial = await repo.historial();
      expect(historial.single.totalCentavos, 250000);
      expect(historial.single.tuvoOferta, isFalse);
    });

    test('con oferta se cobra el precio del escalon', () async {
      await entrarComo('Ana');
      await repo.registrarVenta(
        idProducto: idLenovo,
        idOferta: 2, // el segundo escalon: 20%
      );

      final historial = await repo.historial();
      expect(historial.single.totalCentavos, 200000);
      expect(historial.single.nombreOferta, 'Descuento 20%');
    });

    test('la venta descuenta stock', () async {
      await entrarComo('Ana');
      final antes = repo.producto(idLenovo).stock;

      await repo.registrarVenta(idProducto: idLenovo);

      expect(repo.producto(idLenovo).stock, antes - 1);
    });

    test('sin stock la venta falla', () async {
      final vacio = FakeTiendaRepository(
        productos: [p(idLenovo, 'Agotado', 1000, stock: 0)],
      );
      addTearDown(vacio.cerrar);
      await vacio.registrarCliente(nombre: 'Ana');

      expect(
        () => vacio.registrarVenta(idProducto: idLenovo),
        throwsA(isA<SinStockException>()),
      );
    });
  });

  group('catalogo', () {
    test('solo trae lo disponible', () async {
      final conAgotado = FakeTiendaRepository(
        productos: [
          p(idLenovo, 'Disponible', 1000),
          p(idHp, 'Agotado', 1000, stock: 0),
        ],
      );
      addTearDown(conAgotado.cerrar);

      final catalogo = await conAgotado.catalogo();
      expect(catalogo.map((e) => e.nombre), ['Disponible']);
    });
  });
}
