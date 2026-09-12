/// Lo que la pantalla de ingreso necesita de la autenticacion, y nada mas.
///
/// Existe para que el login se pueda probar. La implementacion real envuelve
/// el SDK de Supabase, que no se construye sin un cliente vivo: pedirlo en el
/// constructor de LoginScreen dejaba la pantalla imposible de montar en una
/// prueba, y es justo donde vive el flujo mas delicado de la app --crear la
/// cuenta, crear la ficha de negocio, y no dejar al usuario a medias entre
/// las dos cosas.
abstract class Autenticacion {
  /// Crea la cuenta.
  ///
  /// Devuelve true si ademas quedo con sesion abierta. Si el proyecto exige
  /// confirmar el correo, devuelve false: la cuenta existe pero falta que el
  /// usuario abra el enlace. No es un error.
  Future<bool> registrarse({required String correo, required String clave});

  Future<void> ingresar({required String correo, required String clave});

  Future<void> cerrarSesion();

  /// Envia el correo para cambiar la clave.
  Future<void> recuperarClave(String correo);
}

/// La cuenta o la clave no son correctas, o el correo ya esta registrado.
///
/// Envuelve el error del proveedor para que la pantalla no tenga que conocer
/// las clases del SDK.
class AutenticacionException implements Exception {
  const AutenticacionException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}
