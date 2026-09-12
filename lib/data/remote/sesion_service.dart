import 'package:supabase_flutter/supabase_flutter.dart';

import 'autenticacion.dart';

/// Registro, ingreso y cierre de sesion contra Supabase Auth.
///
/// La sesion la guarda y refresca el propio SDK en el almacenamiento seguro
/// del dispositivo; aqui no se guarda ninguna credencial. Esa es la diferencia
/// con la version anterior, que dejaba un id de cliente en SharedPreferences:
/// aquello no era identidad, era una nota adhesiva en el telefono.
class SesionService implements Autenticacion {
  SesionService(this._cliente);

  final SupabaseClient _cliente;

  /// La sesion vigente, o null. El SDK la restaura al arrancar la app.
  Session? get sesion => _cliente.auth.currentSession;

  bool get haySesion => sesion != null;

  String? get correo => _cliente.auth.currentUser?.email;

  /// Cambios de sesion: entrar, salir, o el refresco del token. La app se
  /// suscribe para llevar al usuario al login cuando su sesion caduca.
  Stream<AuthState> get cambios => _cliente.auth.onAuthStateChange;

  /// Crea la cuenta. Devuelve true si ademas quedo con sesion abierta.
  ///
  /// Con "Confirm email" activado --el ajuste por defecto de Supabase-- signUp
  /// no devuelve sesion: la cuenta existe pero sin confirmar. Devolver false
  /// en vez de la AuthResponse entera evita que la pantalla tenga que conocer
  /// las clases del SDK.
  @override
  Future<bool> registrarse({
    required String correo,
    required String clave,
  }) async {
    try {
      final r = await _cliente.auth.signUp(email: correo, password: clave);
      return r.session != null;
    } on AuthException catch (e) {
      throw AutenticacionException(e.message);
    }
  }

  @override
  Future<void> ingresar({
    required String correo,
    required String clave,
  }) async {
    try {
      await _cliente.auth.signInWithPassword(email: correo, password: clave);
    } on AuthException catch (e) {
      throw AutenticacionException(e.message);
    }
  }

  @override
  Future<void> cerrarSesion() => _cliente.auth.signOut();

  /// Envia el correo de recuperacion. No se distingue si la cuenta existe: eso
  /// diria a cualquiera que correos estan registrados en la tienda.
  @override
  Future<void> recuperarClave(String correo) async {
    try {
      await _cliente.auth.resetPasswordForEmail(correo);
    } on AuthException catch (e) {
      throw AutenticacionException(e.message);
    }
  }
}
