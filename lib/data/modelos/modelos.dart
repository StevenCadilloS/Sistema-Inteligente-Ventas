/// Modelos del dominio.
///
/// Objetos de lectura, inmutables, sin dependencia de ningun motor de base de
/// datos: las pruebas construyen un catalogo en memoria sin levantar nada.
///
/// Las claves de los mapas son las columnas de PostgreSQL en snake_case, que
/// es como las devuelve PostgREST.
library;

/// Un producto del catalogo, tal como lo publica la vista `v_catalogo`.
class Producto {
  const Producto({
    required this.idProducto,
    required this.nombre,
    required this.precioCentavos,
    this.descripcion,
    this.idCategoria,
    this.categoria,
    this.idMarca,
    this.marca,
    this.imagen,
    this.stock = 0,
    this.activo = true,
    this.tieneOfertas = false,
  });

  final int idProducto;
  final String nombre;
  final String? descripcion;

  /// Precio normal, siempre en centavos enteros: el dinero nunca pasa por
  /// punto flotante. S/2500.00 se guarda como 250000.
  final int precioCentavos;

  final int? idCategoria;
  final String? categoria;
  final int? idMarca;
  final String? marca;

  /// Nombre del archivo en `assets/products/` o URL completa.
  final String? imagen;

  final int stock;
  final bool activo;

  /// Si el producto tiene al menos una oferta vigente configurada. Lo calcula
  /// la vista, y sirve para no encender la camara cuando no hay a donde
  /// avanzar: sin ofertas, el precio se queda en el normal pase lo que pase
  /// con la cara del cliente (README, regla 8).
  final bool tieneOfertas;

  bool get disponible => activo && stock > 0;

  factory Producto.desdeFila(Map<String, dynamic> fila) => Producto(
    idProducto: _entero(fila['id_producto']),
    nombre: fila['nombre'] as String,
    descripcion: fila['descripcion'] as String?,
    precioCentavos: _entero(fila['precio_centavos']),
    idCategoria: fila['id_categoria'] == null
        ? null
        : _entero(fila['id_categoria']),
    categoria: fila['categoria'] as String?,
    idMarca: fila['id_marca'] == null ? null : _entero(fila['id_marca']),
    marca: fila['marca'] as String?,
    imagen: fila['imagen'] as String?,
    stock: _entero(fila['stock']),
    activo: fila['activo'] as bool? ?? true,
    tieneOfertas: fila['tiene_ofertas'] as bool? ?? false,
  );

  Producto copyWith({int? precioCentavos, int? stock}) => Producto(
    idProducto: idProducto,
    nombre: nombre,
    descripcion: descripcion,
    precioCentavos: precioCentavos ?? this.precioCentavos,
    idCategoria: idCategoria,
    categoria: categoria,
    idMarca: idMarca,
    marca: marca,
    imagen: imagen,
    stock: stock ?? this.stock,
    activo: activo,
    tieneOfertas: tieneOfertas,
  );

  @override
  bool operator ==(Object other) =>
      other is Producto && other.idProducto == idProducto;

  @override
  int get hashCode => idProducto.hashCode;
}

/// Un escalon de la secuencia de ofertas de un producto.
///
/// El sistema no inventa descuentos: sube por esta escalera, que un
/// administrador configuro antes en `ofertas_productos.orden`. El
/// `precioFinalCentavos` lo calcula el servidor, no la app, para que el precio
/// que se muestra y el que se cobra salgan de la misma formula.
class EscalonOferta {
  const EscalonOferta({
    required this.orden,
    required this.idOferta,
    required this.nombreOferta,
    required this.tipo,
    required this.precioFinalCentavos,
    this.porcentajeDescuento,
  });

  /// Posicion en la secuencia, empezando en 1.
  final int orden;

  final int idOferta;
  final String nombreOferta;

  /// 'Descuento' o 'Combo'. Una oferta es de una clase o de la otra, nunca de
  /// las dos: lo garantiza `chk_oferta_coherente` en la base.
  final String tipo;

  /// Porcentaje entero (20 = 20%). Nulo cuando la oferta es un combo, que fija
  /// el precio final en vez de rebajar un porcentaje.
  final int? porcentajeDescuento;

  /// Lo que el cliente pagaria en este escalon, en centavos.
  final int precioFinalCentavos;

  bool get esCombo => porcentajeDescuento == null;

  factory EscalonOferta.desdeFila(Map<String, dynamic> fila) => EscalonOferta(
    orden: _entero(fila['orden']),
    idOferta: _entero(fila['id_oferta']),
    nombreOferta: fila['nombre_oferta'] as String,
    tipo: fila['tipo'] as String,
    porcentajeDescuento: fila['porcentaje_descuento'] == null
        ? null
        : _entero(fila['porcentaje_descuento']),
    precioFinalCentavos: _entero(fila['precio_final_centavos']),
  );
}

/// Una venta del historial, una fila por compra (no por linea).
///
/// Antes el historial devolvia una fila por linea de detalle unida a la
/// cabecera, y una compra con dos productos aparecia como dos tarjetas con el
/// mismo total: parecia un doble cobro. Ahora la lista pinta ventas y el
/// detalle vive en su propia pantalla.
class VentaResumen {
  const VentaResumen({
    required this.idVenta,
    required this.fecha,
    required this.lineas,
    required this.unidades,
    required this.totalCentavos,
  });

  final int idVenta;
  final DateTime fecha;

  /// Cuantos productos distintos trae la compra.
  final int lineas;

  /// Cuantas unidades en total: dos mouses y una laptop son 3.
  final int unidades;

  final int totalCentavos;

  /// Lo que la tarjeta de la lista muestra como resumen: "2 productos".
  String get resumenUnidades =>
      unidades == 1 ? '1 unidad' : '$unidades unidades';

  factory VentaResumen.desdeFila(Map<String, dynamic> fila) => VentaResumen(
    idVenta: _entero(fila['id_venta']),
    fecha: DateTime.parse(fila['fecha_hora'] as String).toLocal(),
    lineas: _entero(fila['lineas']),
    unidades: _entero(fila['unidades']),
    totalCentavos: _entero(fila['total_centavos']),
  );
}

/// Una linea del detalle de una venta ya confirmada.
class LineaVenta {
  const LineaVenta({
    required this.producto,
    required this.cantidad,
    required this.precioTotalCentavos,
    this.nombreOferta,
  });

  final String producto;
  final int cantidad;

  /// Lo que se pago por la linea completa, congelado al momento de la compra.
  final int precioTotalCentavos;

  /// Nulo cuando la linea quedo a precio normal.
  final String? nombreOferta;

  bool get tuvoOferta => nombreOferta != null;

  factory LineaVenta.desdeFila(Map<String, dynamic> fila) => LineaVenta(
    producto: fila['producto'] as String,
    cantidad: _entero(fila['cantidad']),
    precioTotalCentavos: _entero(fila['precio_total_centavos']),
    nombreOferta: fila['nombre_oferta'] as String?,
  );
}

/// El detalle completo de una venta: su resumen y las lineas que la componen.
class VentaDetalle {
  const VentaDetalle({required this.resumen, required this.lineas});

  final VentaResumen resumen;
  final List<LineaVenta> lineas;
}

/// Una linea del carrito.
///
/// El cliente la armo negociando: el precio que vio en pantalla queda
/// congelado en [acordadoCentavos] y viaja a fn_confirmar_carrito, que lo
/// usa para REFUSAR si el catalogo ya dice otra cosa -- nunca para cobrar.
class LineaCarrito {
  const LineaCarrito({
    required this.producto,
    required this.cantidad,
    required this.idOferta,
    required this.acordadoCentavos,
  });

  final Producto producto;

  /// Cuantas unidades de este producto hay en la linea.
  final int cantidad;

  /// La oferta que se nego por producto, o null si quedo a precio normal.
  final int? idOferta;

  /// Con cuanto centavos se acordo cada unidad.
  final int acordadoCentavos;

  int get totalCentavos => acordadoCentavos * cantidad;

  /// La misma linea con [cantidad] unidades. La mutacion del carrito real la
  /// hace la pantalla reemplazando la linea entera.
  LineaCarrito conCantidad(int cantidad) => LineaCarrito(
    producto: producto,
    cantidad: cantidad,
    idOferta: idOferta,
    acordadoCentavos: acordadoCentavos,
  );

  @override
  bool operator ==(Object other) =>
      other is LineaCarrito &&
      other.producto.idProducto == producto.idProducto &&
      other.idOferta == idOferta;

  @override
  int get hashCode => Object.hash(producto.idProducto, idOferta);
}

/// Lo que el servidor cotiza por una linea del carrito EN ESTE MOMENTO.
///
/// Son los datos del aviso: si [precioUnitarioCentavos] ya no es el acordado,
/// si [ofertaAplicada] cae a false con una oferta pedida, o si
/// [stockSuficiente] se apaga, la pantalla lo muestra antes de confirmar.
class CotizacionLinea {
  const CotizacionLinea({
    required this.idProducto,
    required this.cantidad,
    required this.idOferta,
    required this.precioUnitarioCentavos,
    required this.ofertaAplicada,
    required this.stockSuficiente,
  });

  final int idProducto;
  final int cantidad;

  /// La que el servidor gasto para cotizar, o null si quedo a precio normal.
  final int? idOferta;
  final int precioUnitarioCentavos;
  final bool ofertaAplicada;
  final bool stockSuficiente;

  factory CotizacionLinea.desdeFila(Map<String, dynamic> fila) =>
      CotizacionLinea(
        idProducto: _entero(fila['id_producto']),
        cantidad: _entero(fila['cantidad']),
        idOferta: fila['id_oferta'] == null
            ? null
            : _entero(fila['id_oferta']),
        precioUnitarioCentavos: _entero(fila['precio_unitario_centavos']),
        ofertaAplicada: fila['oferta_aplicada'] as bool? ?? false,
        stockSuficiente: fila['stock_suficiente'] as bool? ?? false,
      );

  /// La cotizacion respeta la linea que el cliente ya tenia en pantalla:
  /// misma oferta y mismo precio. Es lo que decide si hay que avisar.
  bool respeta(LineaCarrito linea) =>
      idProducto == linea.producto.idProducto &&
      precioUnitarioCentavos == linea.acordadoCentavos &&
      stockSuficiente;
}

/// Formatea centavos como soles: 225000 -> "S/2250.00".
///
/// Vive aqui y no en cada pantalla porque el redondeo tiene que ser el mismo
/// en todas: un precio que se ve distinto en el feed y en el popup parece un
/// error de la tienda.
String soles(int centavos) => 'S/${(centavos / 100).toStringAsFixed(2)}';

/// PostgREST puede devolver un entero como `int` o, si la columna es bigint o
/// viene de un calculo, como `num`. Un cast directo a `int` falla en el
/// segundo caso y tumba la pantalla entera por un dato correcto.
int _entero(Object? valor) => (valor as num?)?.toInt() ?? 0;
