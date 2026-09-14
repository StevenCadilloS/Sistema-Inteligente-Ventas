import 'package:flutter/material.dart';
import '../../data/modelos/modelos.dart';
import '../../theme/app_theme.dart';
import 'imagen_producto.dart';

class ProductoCard extends StatelessWidget {
  const ProductoCard({
    super.key,
    required this.producto,
    required this.destacado,
    required this.seleccionado,
    required this.comprado,
    required this.negociable,
    required this.estilo,
    required this.onTap,
  });

  final Producto producto;
  final bool destacado;
  final bool seleccionado;

  /// Ya esta en el carrito del cliente: no se vuelve a ofertar.
  final bool comprado;

  /// Al cliente de la sesion le queda la oferta del dia. Con el cupo gastado
  /// la etiqueta cambia para avisar claramente que ya no puede usar otra
  /// oferta durante el dia.
  final bool negociable;

  final EmotionStyle estilo;
  final VoidCallback onTap;

  /// Pasa [hijo] a escala de grises cuando [gris]; si no, lo deja igual.
  ///
  /// Los coeficientes son los de luminancia de Rec. 709: un gris plano
  /// (promediar los tres canales) apaga los rojos y aviva los azules, y las
  /// fotos de producto quedan sucias.
  static Widget _talVezEnGris(bool gris, Widget hijo) {
    if (!gris) return hijo;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      child: hijo,
    );
  }

  /// La franja de "AGOTADO", inclinada como un sello.
  static Widget _franjaAgotado() {
    return Transform.rotate(
      angle: -0.16,
      child: Container(
        // Sin `alignment`: un Container que lo lleva se estira a todo el
        // espacio disponible, y la franja tapaba la tarjeta entera. El texto
        // ya se centra con su propio textAlign.
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFBBF24),
          border: const Border.symmetric(
            horizontal: BorderSide(color: Color(0xFFB45309), width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'AGOTADO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF422006),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }

  (IconData, Color) get _visualCategoria {
    const iconos = [
      Icons.devices_other,
      Icons.chair_outlined,
      Icons.checkroom,
      Icons.spa_outlined,
      Icons.local_mall_outlined,
    ];
    const colores = [
      Color(0xFF0891B2),
      Color(0xFF7C3AED),
      Color(0xFFDB2777),
      Color(0xFF059669),
      Color(0xFFEA580C),
    ];
    final indice =
        (producto.categoria ?? '${producto.idProducto}').hashCode.abs() %
            iconos.length;
    return (iconos[indice], colores[indice]);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icono, color) = _visualCategoria;
    // El catalogo muestra siempre el precio normal. Las rebajas no viven
    // aqui: aparecen durante la negociacion, cuando el cliente selecciona el
    // producto y la camara empieza a leer su respuesta.
    final precio = soles(producto.precioCentavos);

    // Sin stock, pero sigue en el feed: se apaga y se marca en vez de
    // desaparecer, que es mas confuso cuando el catalogo se actualiza solo
    // por Realtime. No se puede seleccionar mientras este asi.
    final agotado = producto.stock <= 0;

    final bordeColor = seleccionado
        ? Colors.amber
        : destacado
            ? estilo.color
            : AppTheme.border;
    final bordeAncho = seleccionado ? 3.0 : destacado ? 2.0 : 1.0;

    final sombra = seleccionado
        ? [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.6),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ]
        : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: sombra,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: bordeColor,
            width: bordeAncho,
          ),
        ),
        child: InkWell(
          onTap: agotado ? null : onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? Colors.amber.withValues(alpha: 0.15)
                        : color.withValues(alpha: 0.10),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Gris y no solo mas tenue: quitarle el color es lo que
                      // hace que se lea como "no disponible" de un vistazo,
                      // sin tener que llegar al texto.
                      _talVezEnGris(
                        agotado,
                        Center(
                          child: ImagenProducto(
                            producto: producto,
                            respaldo: Icon(icono, size: 40, color: color),
                          ),
                        ),
                      ),
                      if (agotado) ...[
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                        Positioned.fill(child: Center(child: _franjaAgotado())),
                      ],
                      // El catalogo comunica el estado de la oferta diaria.
                      // Mientras haya cupo conserva "Negociable"; cuando el
                      // cliente ya uso su compra con oferta, lo dice de forma
                      // explicita en vez de simplemente ocultar la etiqueta.
                      if (producto.tieneOfertas && !agotado)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: negociable
                                  ? AppTheme.danger
                                  : AppTheme.mutedText,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              negociable ? 'Negociable' : 'Oferta diaria usada',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (seleccionado)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Seleccionado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else if (comprado)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'En tu carrito',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else if (destacado)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: estilo.color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Para ti',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          precio,
                          style: textTheme.titleMedium?.copyWith(
                            // Apagado si no se puede comprar: un precio en
                            // verde invita a una accion que la tarjeta ya no
                            // permite.
                            color: agotado
                                ? AppTheme.mutedText
                                : AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // El stock se pinta siempre, y lo actualiza el servidor por
                    // Realtime: si otro cliente compra la ultima unidad, este
                    // numero baja aqui sin que nadie refresque nada.
                    Text(
                      agotado
                          ? 'Agotado'
                          : producto.stock <= 3
                              ? 'Quedan ${producto.stock}'
                              : '${producto.stock} disponibles',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: agotado || producto.stock <= 3
                            ? AppTheme.danger
                            : AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
