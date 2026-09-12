import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_adaptativa/data/remote/autenticacion.dart';
import 'package:tienda_adaptativa/ui/login_screen.dart';

import '../apoyo/fake_tienda_repository.dart';

/// El flujo mas delicado de la app: crear la cuenta, crear la ficha de negocio
/// y no dejar al usuario a medias entre las dos cosas.
///
/// Ese hueco ya existio: con "Confirm email" activado, signUp no devuelve
/// sesion, el codigo mostraba el aviso y volvia al modo ingreso -- pero nunca
/// llegaba a crear la ficha. Al confirmar el correo e ingresar, el usuario
/// quedaba autenticado y sin cliente: fn_cliente_actual() devolvia null y no
/// podia ni comprar ni ver ofertas, sin ningun error en pantalla.
class _AutenticacionFalsa implements Autenticacion {
  _AutenticacionFalsa({
    this.devuelveSesionAlRegistrar = true,
    this.fallaCon,
  });

  /// Con "Confirm email" activado en Supabase, registrarse NO abre sesion.
  final bool devuelveSesionAlRegistrar;

  /// Si no es null, todas las operaciones fallan con este mensaje.
  final String? fallaCon;

  final List<String> llamadas = [];

  void _quizaFallar() {
    if (fallaCon != null) throw AutenticacionException(fallaCon!);
  }

  @override
  Future<bool> registrarse({
    required String correo,
    required String clave,
  }) async {
    llamadas.add('registrarse($correo)');
    _quizaFallar();
    return devuelveSesionAlRegistrar;
  }

  @override
  Future<void> ingresar({
    required String correo,
    required String clave,
  }) async {
    llamadas.add('ingresar($correo)');
    _quizaFallar();
  }

  @override
  Future<void> cerrarSesion() async => llamadas.add('cerrarSesion');

  @override
  Future<void> recuperarClave(String correo) async {
    llamadas.add('recuperarClave($correo)');
    _quizaFallar();
  }
}

void main() {
  late FakeTiendaRepository repo;
  late _AutenticacionFalsa auth;

  Future<void> montar(
    WidgetTester tester, {
    bool sesionAlRegistrar = true,
    String? falla,
  }) async {
    auth = _AutenticacionFalsa(
      devuelveSesionAlRegistrar: sesionAlRegistrar,
      fallaCon: falla,
    );
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => LoginScreen(autenticacion: auth, tienda: repo),
          '/tienda': (_) => const Scaffold(body: Text('la tienda')),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Rellena el formulario de registro.
  Future<void> rellenarRegistro(
    WidgetTester tester, {
    String nombre = 'Ana',
    String correo = 'ana@ejemplo.com',
    String clave = 'secreta123',
  }) async {
    await tester.tap(find.text('No tengo cuenta, quiero registrarme'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), nombre);
    await tester.enterText(find.widgetWithText(TextField, 'Correo'), correo);
    await tester.enterText(find.widgetWithText(TextField, 'Clave'), clave);
  }

  setUp(() {
    repo = FakeTiendaRepository();
  });

  tearDown(() => repo.cerrar());

  group('validacion antes de llamar al servidor', () {
    testWidgets('no ingresa sin correo ni clave', (tester) async {
      await montar(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Ingresar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('obligatorios'), findsOneWidget);
      expect(auth.llamadas, isEmpty, reason: 'no se gasta un viaje de red');
    });

    testWidgets('no registra sin nombre', (tester) async {
      await montar(tester);
      await rellenarRegistro(tester, nombre: '');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Falta tu nombre'), findsOneWidget);
      expect(auth.llamadas, isEmpty);
    });

    testWidgets('exige seis caracteres de clave', (tester) async {
      await montar(tester);
      await rellenarRegistro(tester, clave: '123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      // El minimo lo impone Supabase; comprobarlo aqui evita el viaje.
      expect(find.textContaining('6 caracteres'), findsOneWidget);
      expect(auth.llamadas, isEmpty);
    });
  });

  group('registro con sesion inmediata', () {
    testWidgets('crea la cuenta, la ficha, y entra', (tester) async {
      await montar(tester, sesionAlRegistrar: true);
      await rellenarRegistro(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(auth.llamadas, ['registrarse(ana@ejemplo.com)']);
      expect(repo.clientes.length, 1, reason: 'la ficha se crea al registrarse');
      expect(find.text('la tienda'), findsOneWidget);
    });
  });

  group('registro con confirmacion de correo pendiente', () {
    testWidgets('avisa y no entra, pero tampoco pierde el paso', (tester) async {
      await montar(tester, sesionAlRegistrar: false);
      await rellenarRegistro(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Revisa tu correo'), findsOneWidget);
      expect(find.text('la tienda'), findsNothing);
      // La ficha NO se puede crear todavia: fn_registrar_cliente exige sesion.
      expect(repo.clientes, isEmpty);
    });

    testWidgets('al ingresar despues, se crea la ficha que faltaba', (tester) async {
      await montar(tester, sesionAlRegistrar: false);
      await rellenarRegistro(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      // Vuelve al modo ingreso. El usuario confirmo su correo y entra.
      await tester.enterText(
          find.widgetWithText(TextField, 'Correo'), 'ana@ejemplo.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Clave'), 'secreta123');
      // El aviso de "revisa tu correo" empuja el boton fuera de la pantalla
      // visible: sin el scroll, el tap no llega y la prueba pasaria sin probar
      // nada.
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Ingresar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Ingresar'));
      await tester.pumpAndSettle();

      expect(repo.clientes.length, 1,
          reason: 'sin esto el usuario queda autenticado y sin cliente');
      expect(find.text('la tienda'), findsOneWidget);
    });
  });

  group('ingreso', () {
    testWidgets('entra y crea la ficha si no la tenia', (tester) async {
      await montar(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Correo'), 'ana@ejemplo.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Clave'), 'secreta123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Ingresar'));
      await tester.pumpAndSettle();

      expect(auth.llamadas, ['ingresar(ana@ejemplo.com)']);
      expect(find.text('la tienda'), findsOneWidget);
    });

    testWidgets('no duplica la ficha de quien ya la tiene', (tester) async {
      // Cliente ya registrado, con sesion abierta.
      await repo.registrarCliente(nombre: 'Ana');
      expect(repo.clientes.length, 1);

      await montar(tester);
      await tester.enterText(
          find.widgetWithText(TextField, 'Correo'), 'ana@ejemplo.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Clave'), 'secreta123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Ingresar'));
      await tester.pumpAndSettle();

      expect(repo.clientes.length, 1, reason: 'volver a entrar no crea otro');
    });

    testWidgets('muestra el error del servidor sin entrar', (tester) async {
      await montar(tester, falla: 'Invalid login credentials');

      await tester.enterText(
          find.widgetWithText(TextField, 'Correo'), 'ana@ejemplo.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Clave'), 'malaclave');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Ingresar'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid login credentials'), findsOneWidget);
      expect(find.text('la tienda'), findsNothing);
    });
  });

  group('recuperar la clave', () {
    testWidgets('exige el correo antes de enviar', (tester) async {
      await montar(tester);

      await tester.tap(find.text('Olvide mi clave'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Escribe tu correo'), findsOneWidget);
      expect(auth.llamadas, isEmpty);
    });

    testWidgets('no revela si la cuenta existe', (tester) async {
      await montar(tester);
      await tester.enterText(
          find.widgetWithText(TextField, 'Correo'), 'quiensea@ejemplo.com');

      await tester.tap(find.text('Olvide mi clave'));
      await tester.pumpAndSettle();

      // "Si esa cuenta existe": decir que no existe diria a cualquiera que
      // correos estan registrados en la tienda.
      expect(find.textContaining('Si esa cuenta existe'), findsOneWidget);
      expect(auth.llamadas, ['recuperarClave(quiensea@ejemplo.com)']);
    });
  });

  group('cambiar entre ingresar y registrarse', () {
    testWidgets('el aviso de confirmacion se limpia al cambiar', (tester) async {
      await montar(tester, sesionAlRegistrar: false);
      await rellenarRegistro(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Revisa tu correo'), findsOneWidget);

      await tester.ensureVisible(
          find.text('No tengo cuenta, quiero registrarme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No tengo cuenta, quiero registrarme'));
      await tester.pumpAndSettle();

      expect(find.text('Revisa tu correo'), findsNothing,
          reason: 'el aviso es de un intento anterior, no del formulario');
    });
  });
}
