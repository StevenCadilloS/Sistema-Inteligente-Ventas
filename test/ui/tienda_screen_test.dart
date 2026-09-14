import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/modelos/modelos.dart';
import 'package:tienda_adaptativa/services/emotion_channel.dart';
import 'package:tienda_adaptativa/ui/tienda_screen.dart';
import 'package:tienda_adaptativa/ui/widgets/chip_emocion.dart';
import 'package:tienda_adaptativa/ui/widgets/popup_oferta.dart';

import '../apoyo/fake_tienda_repository.dart';

/// Pruebas de la pantalla, no del motor.
///
/// El motor ya esta cubierto en negociacion_test.dart. Aqui se comprueba que
/// la interfaz respete el flujo real: la camara decide cuando avanzar por la
/// escalera y el rechazo manual solo abandona la interaccion.
class _CanalFalso implements EmotionChannel {
  _CanalFalso({this.hayCamara = true});

  final bool hayCamara;
  final _control = StreamController<EmocionDetectada>.broadcast();

  @override
  bool get disponible => hayCamara;

  @override
  Stream<EmocionDetectada> get emociones => _control.stream;

  /// Empuja una lectura ya estabilizada, como hace el modulo nativo: no es un
  /// fotograma suelto sino ~1,3 s de cara sostenida.
  void leer(String emocion) {
    if (!_control.isClosed) {
      _control.add(EmocionDetectada(emotion: emocion, confidence: 0.9));
    }
  }

  /// Simula que la camara no se pudo abrir (permiso denegado, u ocupada).
  void fallar() {
    if (!_control.isClosed) _control.addError('camara_no_disponible');
  }

  Future<void> cerrar() => _control.close();
}

void main() {
  const idLenovo = 1;
  const idHp = 2;

  Producto p(int id, String nombre, int precio, {bool ofertas = true}) =>
      Producto(
        idProducto: id,
        nombre: nombre,
        precioCentavos: precio,
        stock: 10,
        tieneOfertas: ofertas,
      );

  EscalonOferta escalon(int orden, int pct, int precio) => EscalonOferta(
    orden: orden,
    idOferta: orden,
    nombreOferta: 'Descuento $pct%',
    tipo: 'Descuento',
    porcentajeDescuento: pct,
    precioFinalCentavos: precio,
  );

  late FakeTiendaRepository repo;
  late _CanalFalso canal;
  var cerroSesion = false;

  /// Monta la tienda con una sesion ya iniciada y el catalogo cargado.
  Future<void> montar(
    WidgetTester tester, {
    bool hayCamara = true,
    Duration ventana = const Duration(milliseconds: 50),
  }) async {
    canal = _CanalFalso(hayCamara: hayCamara);
    cerroSesion = false;

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/tienda',
        routes: {
          '/': (_) => const Scaffold(body: Text('pantalla de login')),
          '/tienda': (_) => TiendaScreen(
            tienda: repo,
            emotionChannel: canal,
            onCerrarSesion: () async => cerroSesion = true,
            ventanaObservacion: ventana,
          ),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Cierra una ventana con mayoria desfavorable para que la camara, y no un
  /// boton, solicite el siguiente escalon de la negociacion.
  Future<void> reaccionDesfavorable(WidgetTester tester) async {
    canal.leer('neutral');
    canal.leer('triste');
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    repo = FakeTiendaRepository(
      productos: [
        p(idLenovo, 'Laptop Lenovo IdeaPad', 250000),
        p(idHp, 'Laptop HP Pavilion', 280000, ofertas: false),
      ],
      escaleras: {
        idLenovo: [
          escalon(1, 10, 225000),
          escalon(2, 20, 200000),
          escalon(3, 30, 175000),
        ],
      },
    );
    await repo.registrarCliente(nombre: 'Ana');
  });

  tearDown(() async {
    await canal.cerrar();
    await repo.cerrar();
  });

  group('catalogo', () {
    testWidgets('pinta los productos que llegan del servidor', (tester) async {
      await montar(tester);

      expect(find.text('Laptop Lenovo IdeaPad'), findsOneWidget);
      expect(find.text('Laptop HP Pavilion'), findsOneWidget);
    });

    testWidgets('el chip de emocion no aparece sin negociacion', (tester) async {
      await montar(tester);

      expect(find.byType(ChipEmocion), findsNothing);
    });

    testWidgets('el chip aparece al empezar a negociar', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      expect(find.byType(ChipEmocion), findsOneWidget);
    });
  });

  group('la etiqueta Negociable segun el cupo', () {
    testWidgets('con cupo, solo los productos con ofertas la llevan',
        (tester) async {
      await montar(tester);

      expect(find.text('Negociable'), findsOneWidget,
          reason: 'solo la Lenovo tiene ofertas; la HP no');
    });

    testWidgets('comprar con oferta la quita del feed al instante',
        (tester) async {
      await montar(tester);
      expect(find.text('Negociable'), findsOneWidget);

      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();
      await reaccionDesfavorable(tester);
      expect(find.text('Oferta 1'), findsOneWidget);
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mi carrito'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar compra'));
      await tester.pumpAndSettle();

      expect(find.text('Negociable'), findsNothing);
      expect(find.text('Oferta diaria usada'), findsOneWidget);
    });

    testWidgets('comprar a precio normal la conserva', (tester) async {
      await montar(tester);
      expect(find.text('Negociable'), findsOneWidget);

      await tester.tap(find.text('Laptop HP Pavilion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mi carrito'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar compra'));
      await tester.pumpAndSettle();

      expect(find.text('Negociable'), findsOneWidget,
          reason: 'el precio normal no consume la oferta del dia');
    });
  });

  group('seleccionar un producto', () {
    testWidgets('abre el popup en el precio normal', (tester) async {
      await montar(tester);

      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      expect(find.text('S/2500.00'), findsWidgets);
      expect(find.text('Precio normal'), findsOneWidget);
    });

    testWidgets('un producto sin escalera no enciende la camara', (tester) async {
      await montar(tester);

      await tester.tap(find.text('Laptop HP Pavilion'));
      await tester.pumpAndSettle();

      expect(find.text('S/2800.00'), findsWidgets);
      expect(find.text('Precio normal'), findsOneWidget);
    });
  });

  group('rechazo manual', () {
    testWidgets('No gracias cierra y no recorre la escalera', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      expect(find.text('S/2500.00'), findsWidgets);
      expect(find.text('Oferta 1'), findsNothing);

      await tester.tap(find.text('No, gracias'));
      await tester.pumpAndSettle();

      expect(find.text('Lo quiero'), findsNothing,
          reason: 'rechazar abandona la negociacion');
      expect(find.text('Oferta 1'), findsNothing,
          reason: 'un click manual nunca debe desbloquear un descuento');
    });
  });

  group('la camara avanza la escalera sola', () {
    testWidgets('una ventana desfavorable pasa de escalon', (tester) async {
      await montar(tester, ventana: const Duration(milliseconds: 50));
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      expect(find.text('S/2500.00'), findsWidgets);

      await reaccionDesfavorable(tester);

      expect(find.text('S/2250.00'), findsWidgets,
          reason: 'la ventana cerro con mayoria desfavorable');
    });

    testWidgets('una ventana favorable mantiene el precio', (tester) async {
      await montar(tester, ventana: const Duration(milliseconds: 50));
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      canal.leer('feliz');
      canal.leer('sorpresa');
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();

      expect(find.text('S/2500.00'), findsWidgets,
          reason: 'sonreir no debe rebajar el precio');
    });

    testWidgets('sin rostro no se mueve', (tester) async {
      await montar(tester, ventana: const Duration(milliseconds: 50));
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      canal.leer('no_face');
      canal.leer('no_face');
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();

      expect(find.text('S/2500.00'), findsWidgets,
          reason: 'no_face no vota: la ventana queda sin senal');
    });
  });

  group('sin camara', () {
    testWidgets('el popup lo dice en vez de esperar', (tester) async {
      await montar(tester, hayCamara: false);

      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      expect(find.text('sin camara'), findsOneWidget);
    });

    testWidgets('sin camara el rechazo no inventa una oferta', (tester) async {
      await montar(tester, hayCamara: false);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No, gracias'));
      await tester.pumpAndSettle();

      expect(find.text('Lo quiero'), findsNothing);
      expect(find.text('Oferta 1'), findsNothing,
          reason: 'sin lectura facial no se recorre la escalera');
    });
  });

  group('agregar al carrito', () {
    testWidgets('Lo quiero agrega al carrito y NO registra la venta',
        (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();
      await reaccionDesfavorable(tester);
      await reaccionDesfavorable(tester);
      expect(find.text('Oferta 2'), findsOneWidget);
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      expect(find.text('Lo quiero'), findsNothing);
      expect(find.text('1'), findsOneWidget);
      expect(repo.ventas, isEmpty);
      expect(find.textContaining('Agregaste Laptop Lenovo'), findsOneWidget);
    });

    testWidgets('el + del carrito agrega una segunda unidad del mismo producto',
        (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mi carrito'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Agregar una unidad'));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsNWidgets(2), reason: 'badge + linea');
    });

    testWidgets('un producto que ya esta en el carrito no renegocia',
        (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      expect(find.text('Lo quiero'), findsNothing);
      expect(find.text('Confirmar compra'), findsOneWidget);
    });
  });

  group('confirmar la compra', () {
    testWidgets('registra TODO el carrito como una sola venta',
        (tester) async {
      await montar(tester);
      // Lenovo con 20%: dos ventanas desfavorables y Lo quiero.
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();
      await reaccionDesfavorable(tester);
      await reaccionDesfavorable(tester);
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      // HP sin oferta.
      await tester.tap(find.text('Laptop HP Pavilion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mi carrito'));
      await tester.pumpAndSettle();
      expect(find.text('S/4800.00'), findsOneWidget,
          reason: 'total: 200000 + 280000 = S/4800.00');
      await tester.tap(find.text('Confirmar compra'));
      await tester.pumpAndSettle();

      final historial = await repo.historial();
      expect(repo.ventas.map((v) => v.idVenta).toSet(), hasLength(1));
      expect(repo.ventas, hasLength(2));
      expect(historial, hasLength(1));
      expect(historial.single.unidades, 2);

      final lenovo = repo.ventas
          .firstWhere((v) => v.idProducto == idLenovo && v.totalCentavos == 200000);
      expect(lenovo.nombreOferta, 'Descuento 20%');
      expect(find.text('2'), findsNothing);
    });

    testWidgets('confirmar a precio normal no usa oferta', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop HP Pavilion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mi carrito'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar compra'));
      await tester.pumpAndSettle();

      expect(repo.ventas.single.nombreOferta, isNull);
      expect(repo.ventas.single.totalCentavos, 280000);
    });

    testWidgets('un cambio de precio avisa y deja decidir', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      repo.cambiarPrecio(idLenovo, 260000);

      await tester.tap(find.byTooltip('Mi carrito'));
      await tester.pumpAndSettle();
      expect(find.text('S/2500.00'), findsWidgets,
          reason: 'la hoja todavia muestra lo acordado');
      expect(find.text('S/2600.00'), findsNothing,
          reason: 'la cotizacion todavia no llego a la pantalla');

      await tester.tap(find.text('Confirmar compra'));
      await tester.pumpAndSettle();

      expect(find.text('Los precios ya no son los mismos'), findsOneWidget);
      expect(find.textContaining('sale a S/2600.00'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.ventas, isEmpty);
      expect(find.text('S/2600.00'), findsNothing,
          reason: 'cancelar mantiene el carrito como estaba');
    });

    testWidgets('aceptar el precio nuevo confirma con el precio del catalogo',
        (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      repo.cambiarPrecio(idLenovo, 260000);
      await tester.tap(find.byTooltip('Mi carrito'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar compra'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar con los nuevos'));
      await tester.pumpAndSettle();

      expect(repo.ventas.single.totalCentavos, 260000,
          reason: 'se cobra lo que el cliente vio en el aviso');
    });

    testWidgets('quitar del carrito confirma el resto', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laptop HP Pavilion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      repo.cambiarPrecio(idLenovo, 260000);

      await tester.tap(find.byTooltip('Mi carrito'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar compra'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar del carrito'));
      await tester.pumpAndSettle();

      expect(repo.ventas, hasLength(1));
      expect(repo.ventas.single.idProducto, idHp);
    });
  });

  group('cerrar sesion', () {
    testWidgets('el boton avisa a quien monto la pantalla', (tester) async {
      await montar(tester);
      expect(cerroSesion, isFalse);

      await tester.tap(find.byTooltip('Cerrar sesion'));
      await tester.pumpAndSettle();

      expect(cerroSesion, isTrue);
    });

    testWidgets('salir con el popup abierto no deja el overlay flotando', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();
      expect(find.text('No, gracias'), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(PopupOferta),
        matching: find.byIcon(Icons.close),
      ).first);
      await tester.pumpAndSettle();
      expect(find.text('No, gracias'), findsNothing);

      await tester.tap(find.byTooltip('Cerrar sesion'));
      await tester.pumpAndSettle();
      expect(cerroSesion, isTrue);
      expect(find.text('pantalla de login'), findsOneWidget);
    });
  });

  group('salir de la pantalla', () {
    testWidgets('no deja timers vivos', (tester) async {
      await montar(tester, ventana: const Duration(seconds: 30));
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}
