import 'package:shared_preferences/shared_preferences.dart';

import 'tienda_repository.dart';

/// Autenticacion (docs/PLAN_ELVIS.md fase 04). Un cliente se identifica por
/// `codCliente` (formato C0000002, ver docs/MODELO_ANDROID_ROOM.md §3).
///
/// El codigo ya no se genera en el dispositivo: lo asigna el servidor con una
/// secuencia. Cuando la base era local eso funcionaba porque habia un unico
/// escritor; con una base compartida, dos personas registrandose a la vez
/// leian el mismo maximo y la segunda chocaba contra la clave primaria.
///
/// La sesion activa se sigue guardando con SharedPreferences: es estado del
/// dispositivo ("quien esta usando este celular"), no un dato del negocio, y
/// por eso no viaja al servidor. Tampoco es una cache del catalogo — la app no
/// guarda nada del backend en el telefono.
class ClienteRepository {
  ClienteRepository(this._tienda, this._prefs);

  final TiendaRepository _tienda;
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
    final codCliente = await _tienda.registrarCliente(
      nombre: nombre,
      apellido: apellido,
      tipoCliente: tipoCliente,
    );
    await _prefs.setString(_sessionKey, codCliente);
    return codCliente;
  }

  /// Marca `codCliente` como la sesion activa.
  Future<void> iniciarSesion(String codCliente) async {
    if (!await _tienda.existeCliente(codCliente)) {
      throw StateError('No existe un cliente con codigo $codCliente');
    }
    await _prefs.setString(_sessionKey, codCliente);
  }

  /// `codCliente` de la sesion activa, o null si nadie inicio sesion.
  /// Se consulta al arrancar la app para saltar el login.
  String? clienteActivo() => _prefs.getString(_sessionKey);

  Future<void> cerrarSesion() => _prefs.remove(_sessionKey);
}
