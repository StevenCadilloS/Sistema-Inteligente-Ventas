/// Modelos del dominio.
///
/// Antes estas clases las generaba drift a partir de las tablas locales. Al
/// pasar la base a PostgreSQL compartido dejaron de tener dueno, asi que se
/// declaran a mano: son objetos de lectura, inmutables, sin dependencia de
/// ningun motor de base de datos. Eso permite que las pruebas construyan un
/// catalogo en memoria sin levantar nada.
///
/// Las claves de los mapas son las columnas de PostgreSQL en snake_case, que
/// es como las devuelve PostgREST.
library;

/// Un producto del catalogo, tal como lo publica la vista `v_catalogo`: el
/// producto mas la oferta que el administrador tenga vigente sobre el.
class Producto {
  const Producto({
    required this.codLoteProducto,
    required this.nombreProducto,
    required this.precioUnitarioCentavos,
    this.tipoProducto,
    this.nombreTipoProducto,
    this.imagen,
    this.totalDisponible = 0,
    this.totalVecesMostrado = 0,
    this.totalVendidos = 0,
    this.cierresVenta = 0,
    this.activo = true,
    this.descuentoOferta = 0,
    this.nombreOferta,
    this.codOferta,
  });

  final String codLoteProducto;
  final String nombreProducto;
  final String? tipoProducto;
  final String? nombreTipoProducto;

  /// Precio de lista, sin ninguna rebaja. Siempre en centavos enteros: el
  /// dinero nunca pasa por punto flotante (RNF-05).
  final int precioUnitarioCentavos;

  /// Nombre del archivo en `assets/products/` o URL completa. Nulo en los
  /// productos que el administrador crea sin imagen.
  final String? imagen;

  final int totalDisponible;
  final int totalVecesMostrado;
  final int totalVendidos;
  final int cierresVenta;
  final bool activo;

  /// Descuento publicado por el administrador en la tabla `ofertas`, ya
  /// filtrado por vigencia. 0 cuando no hay ninguna oferta activa.
  ///
  /// Es distinto del descuento adaptativo que calcula AdaptationEngine a
  /// partir de la emocion: este lo decide una persona y vive en la base, aquel
  /// lo decide la cara del cliente y vive en una decision.
  final int descuentoOferta;
  final String? nombreOferta;
  final String? codOferta;

  bool get enOferta => descuentoOferta > 0;

  bool get disponible => activo && totalDisponible > 0;

  /// Precio que ve el cliente en el catalogo: el de lista menos la oferta del
  /// administrador, si la hay. Division entera, igual que en la vista SQL.
  int get precioVigenteCentavos =>
      precioUnitarioCentavos - (precioUnitarioCentavos * descuentoOferta ~/ 100);

  factory Producto.desdeFila(Map<String, dynamic> fila) => Producto(
    codLoteProducto: fila['cod_lote_producto'] as String,
    nombreProducto: fila['nombre_producto'] as String,
    tipoProducto: fila['tipo_producto'] as String?,
    nombreTipoProducto: fila['nombre_tipo_producto'] as String?,
    precioUnitarioCentavos: _entero(fila['precio_unitario_centavos']),
    imagen: fila['imagen'] as String?,
    totalDisponible: _entero(fila['total_disponible']),
    totalVecesMostrado: _entero(fila['total_veces_mostrado']),
    totalVendidos: _entero(fila['total_vendidos']),
    cierresVenta: _entero(fila['cierres_venta']),
    activo: fila['activo'] as bool? ?? true,
    descuentoOferta: _entero(fila['descuento_oferta']),
    nombreOferta: fila['nombre_oferta'] as String?,
    codOferta: fila['cod_oferta'] as String?,
  );

  Producto copyWith({int? totalDisponible, int? totalVecesMostrado}) => Producto(
    codLoteProducto: codLoteProducto,
    nombreProducto: nombreProducto,
    tipoProducto: tipoProducto,
    nombreTipoProducto: nombreTipoProducto,
    precioUnitarioCentavos: precioUnitarioCentavos,
    imagen: imagen,
    totalDisponible: totalDisponible ?? this.totalDisponible,
    totalVecesMostrado: totalVecesMostrado ?? this.totalVecesMostrado,
    totalVendidos: totalVendidos,
    cierresVenta: cierresVenta,
    activo: activo,
    descuentoOferta: descuentoOferta,
    nombreOferta: nombreOferta,
    codOferta: codOferta,
  );

  @override
  bool operator ==(Object other) =>
      other is Producto && other.codLoteProducto == codLoteProducto;

  @override
  int get hashCode => codLoteProducto.hashCode;
}

/// Estrategia comercial con su desempeno acumulado, tal como lo publica la
/// vista `v_estrategia_desempeno`.
///
/// `intentos` y `exitos` llegan calculados desde la base en la misma consulta
/// que trae la estrategia. Antes eran dos GROUP BY que el dispositivo lanzaba
/// por separado en cada decision; ahora es un solo viaje de red, que en una
/// base remota importa mucho mas que en una local.
class Estrategia {
  const Estrategia({
    required this.codEstrategia,
    required this.nombreEstrategia,
    this.activo = true,
    this.intentos = 0,
    this.exitos = 0,
  });

  final String codEstrategia;
  final String nombreEstrategia;
  final bool activo;

  /// Procesos de persuasion distintos en los que se aplico (no filas de
  /// interaccion: un mismo proceso puede tener varias).
  final int intentos;

  /// De esos procesos, cuantos terminaron en venta.
  final int exitos;

  factory Estrategia.desdeFila(Map<String, dynamic> fila) => Estrategia(
    codEstrategia: fila['cod_estrategia'] as String,
    nombreEstrategia: fila['nombre_estrategia'] as String,
    activo: fila['activo'] as bool? ?? true,
    intentos: _entero(fila['intentos']),
    exitos: _entero(fila['exitos']),
  );

  @override
  bool operator ==(Object other) =>
      other is Estrategia && other.codEstrategia == codEstrategia;

  @override
  int get hashCode => codEstrategia.hashCode;
}

/// Una fila del historial: la interaccion con los nombres ya resueltos, que es
/// lo unico que la pantalla necesita mostrar.
class InteraccionHistorial {
  const InteraccionHistorial({
    required this.idProcesoPersuasion,
    required this.codCliente,
    required this.nivelDeInteres,
    required this.fecha,
    this.nombreGesto,
    this.nombreEstrategia,
    this.nombreProducto,
  });

  final String idProcesoPersuasion;
  final String codCliente;
  final int nivelDeInteres;
  final DateTime fecha;
  final String? nombreGesto;
  final String? nombreEstrategia;
  final String? nombreProducto;

  /// PostgREST devuelve los joins anidados como mapas: `gestos` es null si la
  /// interaccion se registro con una emocion fuera del catalogo (por ejemplo
  /// cuando el rostro salio de cuadro).
  factory InteraccionHistorial.desdeFila(Map<String, dynamic> fila) {
    String? nombreDe(String tabla, String campo) {
      final anidado = fila[tabla];
      return anidado is Map ? anidado[campo] as String? : null;
    }

    return InteraccionHistorial(
      idProcesoPersuasion: fila['id_proceso_persuasion'] as String,
      codCliente: fila['cod_cliente'] as String,
      nivelDeInteres: _entero(fila['nivel_de_interes']),
      fecha: DateTime.parse(fila['timestamp'] as String).toLocal(),
      nombreGesto: nombreDe('gestos', 'nombre_gesto'),
      nombreEstrategia: nombreDe('estrategias', 'nombre_estrategia'),
      nombreProducto: nombreDe('productos', 'nombre_producto'),
    );
  }
}

/// PostgREST puede devolver un entero como `int` o, si la columna es bigint o
/// viene de un calculo, como `num`. Un cast directo a `int` falla en el
/// segundo caso y tumba la pantalla entera por un dato correcto.
int _entero(Object? valor) => (valor as num?)?.toInt() ?? 0;
