import 'package:supabase_flutter/supabase_flutter.dart';

/// Registro, ingreso y cierre de sesion contra Supabase Auth.
///
/// La sesion la guarda y refresca el propio SDK en el almacenamiento seguro
/// del dispositivo; aqui no se guarda ninguna credencial. Esa es la diferencia
/// con la version anterior, que dejaba un id de cliente en SharedPreferences:
/// aquello no era identidad, era una nota adhesiva en el telefono.
class SesionService {
  SesionService(this._cliente);

  final SupabaseClient _cliente;

  /// La sesion vigente, o null. El SDK la restaura al arrancar la app.
  Session? get sesion => _cliente.auth.currentSession;

  bool get haySesion => sesion != null;

  String? get correo => _cliente.auth.currentUser?.email;

  /// Cambios de sesion: entrar, salir, o el refresco del token. La app se
  /// suscribe para llevar al usuario al login cuando su sesion caduca.
  Stream<AuthState> get cambios => _cliente.auth.onAuthStateChange;

  /// Crea la cuenta. Segun la configuracion del proyecto, Supabase puede exigir
  /// confirmar el correo antes de dejar entrar: en ese caso [Session] viene
  /// null y no es un error, sino que falta ese paso.
  Future<AuthResponse> registrarse({
    required String correo,
    required String clave,
  }) {
    return _cliente.auth.signUp(email: correo, password: clave);
  }

  Future<AuthResponse> ingresar({
    required String correo,
    required String clave,
  }) {
    return _cliente.auth.signInWithPassword(email: correo, password: clave);
  }

  Future<void> cerrarSesion() => _cliente.auth.signOut();

  /// Envia el correo de recuperacion. No se distingue si la cuenta existe: eso
  /// diria a cualquiera que correos estan registrados en la tienda.
  Future<void> recuperarClave(String correo) =>
      _cliente.auth.resetPasswordForEmail(correo);
}
