import '../modelos/modelos.dart';

/// Todo lo que la app necesita de la base compartida, y nada mas.
///
/// El motor de decision y el aprendizaje hablan con esta interfaz, no con
/// Supabase. Dos consecuencias practicas:
///
///   - Las reglas de negocio se pueden probar sin red ni servidor: las pruebas
///     usan una implementacion en memoria (`test/apoyo/fake_tienda_repository.dart`).
///   - Si manana el backend cambia, cambia una clase; AdaptationEngine y
///     BanditOptimizer no se enteran.
///
/// Nota sobre las escrituras: solo hay tres, y las tres son llamadas a
/// funciones del servidor, no INSERT sueltos. No es un detalle de estilo — la
/// atomicidad entre dispositivos (correlativos que no chocan, stock que no se
/// vende dos veces) solo se puede garantizar donde estan los datos.
abstract class TiendaRepository {
  /// Catalogo completo con el stock y las ofertas vigentes en este momento.
  Future<List<Producto>> catalogo();

  /// El mismo catalogo, pero empujado por el servidor cada vez que el
  /// administrador cambia un producto, su stock o una oferta.
  ///
  /// Emite la foto actual al suscribirse y una lista nueva completa en cada
  /// cambio; el consumidor no necesita saber que cambio.
  Stream<List<Producto>> observarCatalogo();

  /// Estrategias activas con sus intentos y exitos ya calculados. Es lo que
  /// alimenta al UCB1.
  Future<List<Estrategia>> estrategiasActivas();

  /// Codigo del ultimo producto que se le mostro a este cliente, o null si no
  /// tiene historial. Lo usa la regla de `enojo` para cambiar de categoria.
  Future<String?> ultimoProductoMostrado(String codCliente);

  /// Registra el intento de persuasion y devuelve su `idProcesoPersuasion`
  /// (C1), que es la clave con la que despues se cierra la venta.
  ///
  /// [emocion] es el nombre que produce el clasificador ("triste"), no el
  /// codigo de gesto: el modulo Kotlin no conoce el catalogo. Una emocion no
  /// catalogada se registra igual, sin gesto.
  Future<String> registrarInteraccion({
    required String codCliente,
    required String emocion,
    required String codLoteProducto,
    String? codEstrategia,
    required int nivelDeInteres,
  });

  /// Cierra el proceso con una venta: cabecera, detalle y descuento de stock,
  /// todo en la misma transaccion del servidor.
  ///
  /// El rechazo no llama a nada: la ausencia de venta con ese
  /// `idProcesoPersuasion` es el rechazo (asi lo mide el KPI 2).
  ///
  /// Lanza [SinStockException] si otro cliente se llevo la ultima unidad
  /// mientras este miraba la oferta.
  Future<void> registrarVenta({
    required String idProcesoPersuasion,
    int? precioFinalCentavos,
  });

  /// Da de alta un cliente y devuelve el `codCliente` que asigno el servidor.
  Future<String> registrarCliente({
    required String nombre,
    required String apellido,
    String? tipoCliente,
  });

  Future<bool> existeCliente(String codCliente);

  /// Ultimas interacciones del cliente, con los nombres ya resueltos.
  Future<List<InteraccionHistorial>> historial(
    String codCliente, {
    int limite = 50,
  });

  /// Dispara el cierre diario en el servidor. Es idempotente: recalcula los
  /// contadores derivados desde las bitacoras en lugar de acumular.
  Future<void> ejecutarCierreDiario();
}

/// El producto se agoto entre que se genero la oferta y que el cliente la
/// acepto. Con una base compartida esto ya no es un caso teorico: basta con
/// que dos personas miren la ultima unidad a la vez.
class SinStockException implements Exception {
  const SinStockException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// La app no tiene a donde conectarse: falta configurar SUPABASE_URL y
/// SUPABASE_ANON_KEY al compilar. Se distingue de un fallo de red para poder
/// decirle al usuario que hacer en vez de un "error de conexion" generico.
///
/// Hoy no la lanza nadie: el caso se detecta antes de construir el
/// repositorio, en `main()`, comprobando `SupabaseConfig.configurado`, y se
/// resuelve mostrando [AppSinBackend] en vez de arrancar la tienda. Se
/// conserva para quien implemente [TiendaRepository] contra otro backend que
/// solo pueda descubrir la falta de credenciales al primer viaje de red.
class BackendNoConfiguradoException implements Exception {
  const BackendNoConfiguradoException();

  @override
  String toString() =>
      'Falta configurar el backend: compila con --dart-define-from-file=env.json '
      '(ver supabase/README.md).';
}
