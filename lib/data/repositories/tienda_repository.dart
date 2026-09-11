import '../modelos/modelos.dart';

/// Todo lo que la app necesita de la base compartida, y nada mas.
///
/// La UI habla con esta interfaz, no con Supabase. Dos consecuencias
/// practicas:
///
///   - Las reglas se pueden probar sin red ni servidor: las pruebas usan una
///     implementacion en memoria (`test/apoyo/fake_tienda_repository.dart`).
///   - Si manana el backend cambia, cambia una clase; la UI no se entera.
///
/// Nota sobre las escrituras: solo hay dos, y las dos son llamadas a funciones
/// del servidor, no INSERT sueltos. No es un detalle de estilo — la clave
/// publica viaja dentro del APK, asi que la app tiene permiso de lectura y
/// nada mas. Quien quiera cobrar un precio distinto tendria que convencer a
/// `fn_registrar_venta`, que recalcula el precio desde el catalogo en vez de
/// creerle a quien la llama.
abstract class TiendaRepository {
  /// Catalogo completo con el stock de este momento.
  Future<List<Producto>> catalogo();

  /// El mismo catalogo, pero empujado por el servidor cada vez que el
  /// administrador cambia un producto, su stock o una oferta.
  ///
  /// Emite la foto actual al suscribirse y una lista nueva completa en cada
  /// cambio; el consumidor no necesita saber que cambio.
  Stream<List<Producto>> observarCatalogo();

  /// La escalera de ofertas de [idProducto] para el cliente de la sesion, en
  /// orden.
  ///
  /// Viene vacia por cualquiera de estas razones, y a la app le da igual cual:
  /// el producto no tiene ofertas configuradas, ninguna esta vigente hoy, o el
  /// cliente ya gasto sus dos ofertas del dia. En los tres casos la respuesta
  /// es la misma: se queda en el precio normal.
  Future<List<EscalonOferta>> ofertasDe(int idProducto);

  /// Si al cliente de la sesion le queda derecho a usar ofertas hoy. Lo decide
  /// el servidor contando sus compras del dia, no la app.
  ///
  /// Sirve para no encender la camara cuando no hay nada que negociar; la
  /// comprobacion de verdad la vuelve a hacer el servidor al vender.
  Future<bool> puedeUsarOferta();

  /// Registra la compra: cabecera, detalle y descuento de stock, todo en la
  /// misma transaccion del servidor.
  ///
  /// [idOferta] nulo significa compra a precio normal. El precio NO se manda:
  /// lo recalcula el servidor desde el catalogo y la oferta.
  ///
  /// Lanza [SinStockException] si otro cliente se llevo la ultima unidad
  /// mientras este decidia, y [LimiteOfertasException] si intenta usar una
  /// oferta habiendo agotado su cupo del dia.
  Future<int> registrarVenta({
    required int idProducto,
    int cantidad = 1,
    int? idOferta,
  });

  /// Crea la ficha de negocio del usuario ya autenticado y devuelve su id.
  ///
  /// El correo no se pasa: lo toma el servidor del token, que es el que
  /// Supabase ya verifico. Si la ficha ya existe, devuelve la suya — volver a
  /// entrar no crea un cliente nuevo.
  Future<int> registrarCliente({
    required String nombre,
    String? paterno,
    String? materno,
    String? telefono,
  });

  /// Id del cliente de la sesion, o null si no ha iniciado sesion o todavia no
  /// completo su ficha.
  Future<int?> clienteActual();

  /// Ultimas compras del cliente de la sesion.
  Future<List<CompraHistorial>> historial({int limite = 50});
}

/// El producto se agoto entre que se mostro la oferta y que el cliente la
/// acepto. Con una base compartida esto no es un caso teorico: basta con que
/// dos personas miren la ultima unidad a la vez.
class SinStockException implements Exception {
  const SinStockException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// El cliente ya uso ofertas en sus dos primeras compras del dia (README,
/// regla 7). Puede seguir comprando, pero a precio normal.
///
/// La app pregunta antes con [TiendaRepository.puedeUsarOferta], asi que
/// llegar aqui significa que el limite se alcanzo mientras el cliente
/// decidia — por ejemplo comprando desde otro dispositivo. Con la sesion
/// atada a una cuenta, eso ya no se esquiva reinstalando la app.
class LimiteOfertasException implements Exception {
  const LimiteOfertasException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// La app no tiene a donde conectarse: falta configurar SUPABASE_URL y la
/// clave publica al compilar. Se distingue de un fallo de red para poder
/// decirle al usuario que hacer en vez de un "error de conexion" generico.
///
/// Hoy no la lanza nadie: el caso se detecta antes de construir el
/// repositorio, en `main()`, comprobando `SupabaseConfig.configurado`, y se
/// resuelve mostrando la pantalla de configuracion faltante. Se conserva para
/// quien implemente [TiendaRepository] contra otro backend que solo pueda
/// descubrir la falta de credenciales al primer viaje de red.
class BackendNoConfiguradoException implements Exception {
  const BackendNoConfiguradoException();

  @override
  String toString() =>
      'Falta configurar el backend: compila con --dart-define-from-file=env.json '
      '(ver supabase/README.md).';
}

/// La operacion necesita una sesion iniciada y no la hay.
///
/// Casi todo lo que hace la tienda exige identidad: sin ella no se sabe de
/// quien es el historial ni a quien cargarle el limite de ofertas del dia.
class SinSesionException implements Exception {
  const SinSesionException([
    this.mensaje = 'Hay que iniciar sesion para continuar.',
  ]);
  final String mensaje;

  @override
  String toString() => mensaje;
}
