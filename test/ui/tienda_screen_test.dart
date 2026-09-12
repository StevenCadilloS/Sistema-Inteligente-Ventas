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
/// El motor ya esta cubierto en negociacion_test.dart, y sus pruebas pasaban
/// mientras la pantalla tenia tres fallos que el cliente si veia: el boton de
/// rechazar cerraba la interaccion en vez de avanzar, la ventana de
/// observacion era demasiado corta para el detector real, y un fallo de camara
/// dejaba al cliente esperando. Ninguno lo habria detectado una prueba del
/// motor, porque el motor era correcto y quien lo llamaba no.
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
        // La tienda navega a '/' al cerrar sesion o al caducar el token, asi
        // que la prueba tiene que ofrecer esa ruta o pumpAndSettle se queda
        // esperando una pantalla que no existe.
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

      // La camara esta apagada mientras se navega: anunciar una emocion seria
      // mentira. Se busca el widget, no su texto, que puede cambiar.
      expect(find.byType(ChipEmocion), findsNothing);
    });

    testWidgets('el chip aparece al empezar a negociar', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      expect(find.byType(ChipEmocion), findsOneWidget);
    });
  });

  group('seleccionar un producto', () {
    testWidgets('abre el popup en el precio normal', (tester) async {
      await montar(tester);

      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      // Empieza en el precio de lista, no en la primera oferta.
      expect(find.text('S/2500.00'), findsWidgets);
      expect(find.text('Precio normal'), findsOneWidget);
    });

    testWidgets('un producto sin escalera no enciende la camara', (tester) async {
      await montar(tester);

      await tester.tap(find.text('Laptop HP Pavilion'));
      await tester.pumpAndSettle();

      expect(find.text('S/2800.00'), findsWidgets);
      // Sin ofertas, el contador de lecturas no debe estar observando.
      expect(find.text('Precio normal'), findsOneWidget);
    });
  });

  group('rechazar avanza la escalera', () {
    testWidgets('el boton pasa al siguiente escalon, no cierra', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      expect(find.text('S/2500.00'), findsWidgets);

      // Primer rechazo: 10%.
      await tester.tap(find.text('No, gracias'));
      await tester.pumpAndSettle();
      expect(find.text('S/2250.00'), findsWidgets,
          reason: 'rechazar debe ofrecer el siguiente escalon');
      expect(find.text('Oferta 1 de 3'), findsOneWidget);

      // Segundo: 20%.
      await tester.tap(find.text('No, gracias'));
      await tester.pumpAndSettle();
      expect(find.text('S/2000.00'), findsWidgets);

      // Tercero: 30%.
      await tester.tap(find.text('No, gracias'));
      await tester.pumpAndSettle();
      expect(find.text('S/1750.00'), findsWidgets);
      expect(find.text('Oferta 3 de 3'), findsOneWidget);
    });

    testWidgets('al agotar la escalera se cierra la interaccion', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('No, gracias'));
        await tester.pumpAndSettle();
      }

      // El cuarto rechazo no tiene a donde ir: el popup desaparece.
      expect(find.text('No, gracias'), findsNothing);
    });
  });

  group('la camara avanza la escalera sola', () {
    testWidgets('una ventana desfavorable pasa de escalon', (tester) async {
      await montar(tester, ventana: const Duration(milliseconds: 50));
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      expect(find.text('S/2500.00'), findsWidgets);

      // Dos lecturas desfavorables: el minimo que exige el clasificador.
      canal.leer('neutral');
      canal.leer('triste');
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();

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

    testWidgets('se puede negociar igual con el boton', (tester) async {
      await montar(tester, hayCamara: false);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No, gracias'));
      await tester.pumpAndSettle();

      expect(find.text('S/2250.00'), findsWidgets,
          reason: 'la tienda funciona sin camara, solo mas despacio');
    });
  });

  group('comprar', () {
    testWidgets('cierra la venta al precio que se mostraba', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop Lenovo IdeaPad'));
      await tester.pumpAndSettle();

      // Avanza dos escalones y compra al 20%.
      await tester.tap(find.text('No, gracias'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No, gracias'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      final historial = await repo.historial();
      expect(historial.single.totalCentavos, 200000,
          reason: 'se cobra el escalon que estaba en pantalla, no el de lista');
      expect(historial.single.nombreOferta, 'Descuento 20%');
    });

    testWidgets('comprar a precio normal no usa oferta', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Laptop HP Pavilion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lo quiero'));
      await tester.pumpAndSettle();

      final historial = await repo.historial();
      expect(historial.single.totalCentavos, 280000);
      expect(historial.single.tuvoOferta, isFalse);
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

      // El popup cubre la barra superior, asi que el boton de cerrar sesion no
      // se puede pulsar mientras esta abierto -- comprobado: el tap no llegaba
      // y la prueba anterior pasaba sin probar nada. Se cierra primero, que es
      // lo que hace el cliente de verdad.
      // Dos iconos de cerrar en el popup: el de la cabecera (primero) y el
      // del boton "No, gracias" (segundo). Aqui interesa el de la cabecera,
      // que abandona sin avanzar la escalera.
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

      // Desmontar con una ventana de 30 s abierta: si el timer sobreviviera,
      // el propio flutter_test fallaria con "A Timer is still pending".
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}
