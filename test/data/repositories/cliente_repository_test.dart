import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tienda_adaptativa/data/repositories/cliente_repository.dart';

import '../../apoyo/fake_tienda_repository.dart';

/// Sesion del cliente (docs/PLAN_ELVIS.md fase 04).
///
/// El codigo de cliente ya no se genera aqui: lo asigna el servidor con una
/// secuencia, y que dos registros simultaneos no choquen se prueba en SQL
/// (supabase/tests/01_ciclo_venta.sql). Lo que queda de este lado es la
/// sesion: que se guarde, se recupere y se cierre en el dispositivo.
void main() {
  late FakeTiendaRepository tienda;
  late ClienteRepository clientes;

  setUp(() async {
    tienda = FakeTiendaRepository();
    SharedPreferences.setMockInitialValues({});
    clientes = ClienteRepository(tienda, await SharedPreferences.getInstance());
  });

  tearDown(() => tienda.cerrar());

  test('registrar devuelve el codigo del servidor y deja sesion activa', () async {
    final cod = await clientes.registrar(nombre: 'Carlos', apellido: 'Ramirez');

    expect(cod, 'C0000001');
    expect(clientes.clienteActivo(), 'C0000001');
  });

  test('el segundo registro recibe un codigo distinto', () async {
    final primero = await clientes.registrar(
      nombre: 'Carlos',
      apellido: 'Ramirez',
    );
    final segundo = await clientes.registrar(
      nombre: 'Ana',
      apellido: 'Torres',
    );

    expect(segundo, isNot(primero));
    expect(clientes.clienteActivo(), segundo);
  });

  test('iniciarSesion falla si el codCliente no existe', () async {
    expect(
      () => clientes.iniciarSesion('C9999999'),
      throwsA(isA<StateError>()),
    );
    expect(clientes.clienteActivo(), isNull);
  });

  test('iniciarSesion acepta un cliente ya registrado', () async {
    final cod = await clientes.registrar(nombre: 'Ana', apellido: 'Torres');
    await clientes.cerrarSesion();

    await clientes.iniciarSesion(cod);

    expect(clientes.clienteActivo(), cod);
  });

  test('cerrarSesion limpia el cliente activo', () async {
    await clientes.registrar(nombre: 'Carlos', apellido: 'Ramirez');

    await clientes.cerrarSesion();

    expect(clientes.clienteActivo(), isNull);
  });

  test('tipoCliente nullable: se puede registrar sin el (C3)', () async {
    final cod = await clientes.registrar(
      nombre: 'Luis',
      apellido: 'Vega',
      tipoCliente: null,
    );

    expect(cod, isNotEmpty);
    expect(clientes.clienteActivo(), cod);
  });
}
