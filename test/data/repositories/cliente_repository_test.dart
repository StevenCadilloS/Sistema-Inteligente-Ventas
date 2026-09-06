import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tienda_adaptativa/data/database/app_database.dart';
import 'package:tienda_adaptativa/data/repositories/cliente_repository.dart';

void main() {
  late AppDatabase db;
  late ClienteRepository clientes;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').getSingle(); // dispara onCreate/seed
    SharedPreferences.setMockInitialValues({});
    clientes = ClienteRepository(db, await SharedPreferences.getInstance());
  });

  tearDown(() => db.close());

  test('registrar genera codCliente C0000001 y deja sesion activa',
      () async {
    final cod = await clientes.registrar(nombre: 'Carlos', apellido: 'Ramirez');

    expect(cod, 'C0000001');
    expect(clientes.clienteActivo(), 'C0000001');
  });

  test('el segundo registro continua el secuencial', () async {
    await clientes.registrar(nombre: 'Carlos', apellido: 'Ramirez');
    final segundo =
        await clientes.registrar(nombre: 'Ana', apellido: 'Torres');

    expect(segundo, 'C0000002');
  });

  test('iniciarSesion falla si el codCliente no existe', () async {
    expect(
      () => clientes.iniciarSesion('C9999999'),
      throwsA(isA<StateError>()),
    );
  });

  test('cerrarSesion limpia el cliente activo', () async {
    final cod = await clientes.registrar(nombre: 'Ana', apellido: 'Torres');
    expect(clientes.clienteActivo(), cod);

    await clientes.cerrarSesion();

    expect(clientes.clienteActivo(), isNull);
  });

  test('tipoCliente nullable: se puede registrar sin el (C3)', () async {
    final cod = await clientes.registrar(nombre: 'Ana', apellido: 'Torres');

    final fila = await (db.select(db.clientes)
          ..where((c) => c.codCliente.equals(cod)))
        .getSingle();
    expect(fila.tipoCliente, isNull);
  });
}
