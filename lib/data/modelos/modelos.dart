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

  Producto copyWith({int? stock}) => Producto(
    idProducto: idProducto,
    nombre: nombre,
    descripcion: descripcion,
    precioCentavos: precioCentavos,
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

/// Una fila del historial de compras.
class CompraHistorial {
  const CompraHistorial({
    required this.idVenta,
    required this.fecha,
    required this.producto,
    required this.cantidad,
    required this.totalCentavos,
    this.nombreOferta,
  });

  final int idVenta;
  final DateTime fecha;
  final String producto;
  final int cantidad;
  final int totalCentavos;

  /// Nulo cuando la compra fue a precio normal, sin oferta.
  final String? nombreOferta;

  bool get tuvoOferta => nombreOferta != null;

  factory CompraHistorial.desdeFila(Map<String, dynamic> fila) =>
      CompraHistorial(
        idVenta: _entero(fila['id_venta']),
        fecha: DateTime.parse(fila['fecha_hora'] as String).toLocal(),
        producto: fila['producto'] as String,
        cantidad: _entero(fila['cantidad']),
        totalCentavos: _entero(fila['total_centavos']),
        nombreOferta: fila['nombre_oferta'] as String?,
      );
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
