import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';

/// Autenticacion (docs/PLAN_ELVIS.md fase 04). Un cliente se identifica por
/// `codCliente` (formato C0000002, ver docs/MODELO_ANDROID_ROOM.md §3), que
/// se genera aqui como un secuencial local - no hay servidor que lo asigne.
///
/// La sesion activa se persiste con SharedPreferences (no en la BD: es
/// estado del dispositivo, no un dato del negocio) para que la app no
/// pregunte quien eres en cada arranque.
class ClienteRepository {
  ClienteRepository(this._db, this._prefs);

  final AppDatabase _db;
  final SharedPreferences _prefs;

  static const _sessionKey = 'cod_cliente_activo';

  /// Crea un cliente nuevo y lo deja como sesion activa.
  ///
  /// `tipoCliente` es nullable (C3): el KPI 3 agrupa por el, pero no todos
  /// los clientes lo tienen asignado al registrarse.
  Future<String> registrar({
    required String nombre,
    required String apellido,
    String? tipoCliente,
  }) async {
    // Leer el ultimo codCliente e insertar van en una transaccion: sueltos,
    // dos registros concurrentes podrian generar el mismo codigo y chocar
    // contra la primary key.
    late final String codCliente;
    await _db.transaction(() async {
      codCliente = await _siguienteCodCliente();
      await _db.into(_db.clientes).insert(ClientesCompanion.insert(
            codCliente: codCliente,
            nombre: nombre,
            apellido: apellido,
            tipoCliente: Value(tipoCliente),
            fechaIngreso: DateTime.now().millisecondsSinceEpoch,
          ));
    });
    await iniciarSesion(codCliente);
    return codCliente;
  }

  /// Marca `codCliente` como la sesion activa.
  Future<void> iniciarSesion(String codCliente) async {
    final existe = await (_db.select(_db.clientes)
          ..where((c) => c.codCliente.equals(codCliente)))
        .getSingleOrNull();
    if (existe == null) {
      throw StateError('No existe un cliente con codigo $codCliente');
    }
    await _prefs.setString(_sessionKey, codCliente);
  }

  /// `codCliente` de la sesion activa, o null si nadie inicio sesion.
  /// Se consulta al arrancar la app para saltar el login.
  String? clienteActivo() => _prefs.getString(_sessionKey);

  Future<void> cerrarSesion() => _prefs.remove(_sessionKey);

  Future<String> _siguienteCodCliente() async {
    final ultimo = await (_db.select(_db.clientes)
          ..orderBy([(c) => OrderingTerm.desc(c.codCliente)])
          ..limit(1))
        .getSingleOrNull();

    final siguienteNumero =
        ultimo == null ? 1 : int.parse(ultimo.codCliente.substring(1)) + 1;
    return 'C${siguienteNumero.toString().padLeft(7, '0')}';
  }
}
