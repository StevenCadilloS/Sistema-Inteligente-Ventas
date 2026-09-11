import 'package:shared_preferences/shared_preferences.dart';

import 'tienda_repository.dart';

/// Quien esta usando este celular.
///
/// El id del cliente lo asigna el servidor con una secuencia, no el
/// dispositivo: con una base compartida, dos personas registrandose a la vez
/// leerian el mismo maximo y la segunda chocaria contra la clave primaria.
///
/// La sesion activa se guarda con SharedPreferences porque es estado del
/// dispositivo ("quien esta usando este celular"), no un dato del negocio. No
/// es una cache del catalogo: la app no guarda nada del backend en el
/// telefono.
class ClienteRepository {
  ClienteRepository(this._tienda, this._prefs);

  final TiendaRepository _tienda;
  final SharedPreferences _prefs;

  static const _sessionKey = 'id_cliente_activo';

  /// Crea un cliente nuevo y lo deja como sesion activa.
  Future<int> registrar({
    required String nombre,
    String? paterno,
    String? materno,
    String? telefono,
    String? correo,
  }) async {
    final idCliente = await _tienda.registrarCliente(
      nombre: nombre,
      paterno: paterno,
      materno: materno,
      telefono: telefono,
      correo: correo,
    );
    await _prefs.setInt(_sessionKey, idCliente);
    return idCliente;
  }

  /// Id del cliente de la sesion activa, o null si nadie inicio sesion.
  /// Se consulta al arrancar la app para saltar el login.
  int? clienteActivo() => _prefs.getInt(_sessionKey);

  Future<void> cerrarSesion() => _prefs.remove(_sessionKey);
}
