import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tienda_adaptativa/data/repositories/cliente_repository.dart';

import '../../apoyo/fake_tienda_repository.dart';

/// Sesion del cliente.
///
/// El id ya no se genera aqui: lo asigna el servidor con una secuencia, y que
/// dos registros simultaneos no choquen se prueba en SQL
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

  test('registrar devuelve el id del servidor y deja sesion activa', () async {
    final id = await clientes.registrar(nombre: 'Carlos', paterno: 'Ramirez');

    expect(id, 1);
    expect(clientes.clienteActivo(), 1);
  });

  test('el segundo registro recibe un id distinto', () async {
    final primero = await clientes.registrar(
      nombre: 'Carlos',
      paterno: 'Ramirez',
    );
    final segundo = await clientes.registrar(nombre: 'Ana', paterno: 'Torres');

    expect(segundo, isNot(primero));
    expect(clientes.clienteActivo(), segundo);
  });

  test('cerrarSesion limpia el cliente activo', () async {
    await clientes.registrar(nombre: 'Carlos', paterno: 'Ramirez');

    await clientes.cerrarSesion();

    expect(clientes.clienteActivo(), isNull);
  });

  test('los apellidos y el contacto son opcionales', () async {
    // El unico dato obligatorio es el nombre: lo exige fn_registrar_cliente,
    // que rechaza un nombre vacio con la pista `nombre_vacio`.
    final id = await clientes.registrar(nombre: 'Luis');

    expect(id, isPositive);
    expect(clientes.clienteActivo(), id);
  });
}
